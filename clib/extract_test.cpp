#include "mupdf/fitz.h"
#include <iostream>
#include <string>
#include <stdexcept>
#include <filesystem>
#include <chrono>

namespace fs = std::filesystem;

void extract_page(fz_context* ctx, fz_document* doc, int page_num, const std::string& output_directory, const std::string& output_filename_prefix)
{
    fz_page* page = nullptr;
    fz_document_writer* doc_writer = nullptr;
    fz_device* device = nullptr;
    fz_rect bbox;

    std::string output_filename = output_directory + "/" + output_filename_prefix + "_" + std::to_string(page_num + 1) + ".pdf";

    try {
        fz_try(ctx) {
            page = fz_load_page(ctx, doc, page_num);
            bbox = fz_bound_page(ctx, page);

            doc_writer = fz_new_document_writer(ctx, output_filename.c_str(), "pdf", nullptr);
            device = fz_begin_page(ctx, doc_writer, bbox);

            fz_run_page(ctx, page, device, fz_identity, nullptr);

            fz_end_page(ctx, doc_writer);
            fz_close_document_writer(ctx, doc_writer);
        }
        fz_always(ctx) {
            if (device) fz_drop_device(ctx, device);
            if (doc_writer) fz_drop_document_writer(ctx, doc_writer);
            if (page) fz_drop_page(ctx, page);
        }
        fz_catch(ctx) {
            throw std::runtime_error(fz_caught_message(ctx));
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Error processing page " << page_num << ": " << e.what() << std::endl;
    }
}

int main(int argc, char** argv)
{
    auto start = std::chrono::high_resolution_clock::now();  // 시작 시간 측정

    fz_context* ctx = nullptr;
    fz_document* doc = nullptr;

    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " input.pdf output_prefix" << std::endl;
        return 1;
    }

    std::string input_filename = argv[1];
    std::string output_directory = "output"; // 고정된 출력 디렉토리
    std::string output_prefix = argv[2];

    try {
        if (!fs::exists(output_directory)) {
            fs::create_directories(output_directory);
        }

        ctx = fz_new_context(nullptr, nullptr, FZ_STORE_UNLIMITED);
        if (!ctx) {
            throw std::runtime_error("Cannot create context");
        }

        fz_try(ctx) {
            fz_register_document_handlers(ctx);
            doc = fz_open_document(ctx, input_filename.c_str());
            if (!doc) {
                throw std::runtime_error("Cannot open document");
            }

            int page_count = fz_count_pages(ctx, doc);

            for (int i = 0; i < page_count; ++i) {
                extract_page(ctx, doc, i, output_directory, output_prefix);
            }

            fz_drop_document(ctx, doc);
        }
        fz_always(ctx) {
            if (doc) {
                fz_drop_document(ctx, doc);
                doc = nullptr;
            }
            fz_drop_context(ctx);
        }
        fz_catch(ctx) {
            std::cerr << "MuPDF error: " << fz_caught_message(ctx) << std::endl;
            return 1;
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        if (ctx) {
            fz_drop_context(ctx);
        }
        return 1;
    }

    auto end = std::chrono::high_resolution_clock::now();  // 종료 시간 측정
    std::chrono::duration<double> elapsed = end - start;  // 경과 시간 계산

    std::cout << "Execution time: " << elapsed.count() << " seconds" << std::endl;

    return 0;
}
