#!/bin/sh
BUILD_FOLDER=$1
PRODUCT_NAME=$2

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
WASI_LIBC_DIR=$SCRIPT_DIR/wasi-libc

if [ -z "$BUILD_FOLDER" ] || [ -z "$PRODUCT_NAME" ]; then
    echo "Usage: $0 <build_folder> <product_name> <wasi_lib_path>"
    exit 1
fi

OBJECT_FILE_LIST="$BUILD_FOLDER/$PRODUCT_NAME.product/Objects.LinkFileList"

filtered_object_files() {
    # totally stable and unproblamtic way of only passing the "good" object files
    # thus solving the problem once and for all (https://www.youtube.com/watch?v=0SYpUSjSgFg)
    local result=""

    while IFS= read -r line; do
        case "$line" in
            *.swift.o) 
                case "$line" in
                    */$PRODUCT_NAME.build/*) 
                        result="$result $line"
                        ;;
                esac
                ;;
            *) 
                result="$result $line"
                ;;
        esac
    done

    echo $result
}

wasm-ld \
    --no-entry --export-if-defined=__main_argc_argv --export-if-defined=__main_argc_argv \
    --strip-all -O2 \
    -L"$WASI_LIBC_DIR" \
    -lc \
    $(filtered_object_files <$OBJECT_FILE_LIST) \
    -o "$BUILD_FOLDER/$PRODUCT_NAME.wasm" \

echo "Custom WASM linking succeeded: $BUILD_FOLDER/$PRODUCT_NAME.wasm" 