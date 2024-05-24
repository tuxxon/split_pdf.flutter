#include "mupdf/fitz.h"
#include <iostream>
#include <string>
#include <stdexcept>
#include <filesystem>

namespace fs = std::filesystem;

typedef void (*ProgressCallback)(int currentPage, int totalPages);

int page_count = 0;

extern "C" void split_pdf(const char* input_filename, const char* output_directory, const char* output_prefix, ProgressCallback progressCallback) {
    fz_context* ctx = nullptr;
    fz_document* doc = nullptr;

    try {
        if (!fs::exists(output_directory)) {
            fs::create_directories(output_directory);
        }

        ctx = fz_new_context(nullptr, nullptr, FZ_STORE_UNLIMITED);
        if (!ctx) {
            throw std::runtime_error("Cannot create context");
        }

        fz_register_document_handlers(ctx);
        doc = fz_open_document(ctx, input_filename);
        if (!doc) {
            throw std::runtime_error("Cannot open document");
        }

        page_count = fz_count_pages(ctx, doc);

        for (int i = 0; i < page_count; ++i) {
            fz_page* page = nullptr;
            fz_document_writer* doc_writer = nullptr;
            fz_device* device = nullptr;
            fz_rect bbox;

            std::string output_filename = std::string(output_directory) + "/" + std::string(output_prefix) + "_" + std::to_string(i + 1) + ".pdf";

            fz_try(ctx) {
                page = fz_load_page(ctx, doc, i);
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

            if (progressCallback) {
                progressCallback(i + 1, page_count);
            }
        }

        fz_drop_document(ctx, doc);
        fz_drop_context(ctx);
    }
    catch (const std::exception& e) {
        if (doc) fz_drop_document(ctx, doc);
        if (ctx) fz_drop_context(ctx);
        std::cerr << "Error: " << e.what() << std::endl;
    }
}

extern "C" int get_page_count() {
    return page_count;
}
