#!/bin/bash

# variables

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GRPC_VERSION="1.14.1"

# GRPC-TOOLS required. Install with "nuget install Grpc.Tools -Version $GRPC_VERSION".
# Then export env GRPC_TOOLS with location of files.
if [ -z "$GRPC_TOOLS" ]
then
    echo "Must set env var GRPC_TOOLS to path of Grpc.Tools (nuget install Grpc.Tools -Version $GRPC_VERSION)."
    exit 1
fi
COMPILER=${GRPC_TOOLS}

SRC_DIR=$DIR/proto/mlagents/envs/communicator_objects
DST_DIR_C=$DIR/../UnitySDK/Assets/ML-Agents/Scripts/CommunicatorObjects
DST_DIR_P=$DIR/../ml-agents-envs
PROTO_PATH=$DIR/proto

PYTHON_PACKAGE=mlagents/envs/communicator_objects

# clean
rm -rf $DST_DIR_C
rm -rf $DST_DIR_P/$PYTHON_PACKAGE
mkdir -p $DST_DIR_C
mkdir -p $DST_DIR_P/$PYTHON_PACKAGE

# generate proto objects in python and C#

echo "Compiling Learning Protobuffers:"
echo "  Source: $SRC_DIR"
echo "  C# Destination: $DST_DIR_C"
echo "  Python Destination: $DST_DIR_P"
protoc --proto_path=$PROTO_PATH --csharp_out=$DST_DIR_C $SRC_DIR/*.proto
protoc --proto_path=$PROTO_PATH --python_out=$DST_DIR_P $SRC_DIR/*.proto 

# grpc 

GRPC=unity_to_external.proto

echo "Compiling GRPC Protobuffers:"
echo "  Source: $SRC_DIR/$GRPC"
echo "  C# Destination: $DST_DIR_C"
echo "  Python Destination: $DST_DIR_P"
$COMPILER/protoc --proto_path=$PROTO_PATH --csharp_out $DST_DIR_C --grpc_out $DST_DIR_C $SRC_DIR/$GRPC --plugin=protoc-gen-grpc=$COMPILER/grpc_csharp_plugin
python3 -m grpc_tools.protoc --proto_path=$PROTO_PATH --python_out=$DST_DIR_P --grpc_python_out=$DST_DIR_P $SRC_DIR/$GRPC 

# Generate the init file for the python module
# rm -f $DST_DIR_P/$PYTHON_PACKAGE/__init__.py
echo "Adding python packages to init file ($DST_DIR_P/$PYTHON_PACKAGE/__init__.py):"
for FILE in $DST_DIR_P/$PYTHON_PACKAGE/*.py
do 
    FILE=${FILE##*/}
    echo "  * ${FILE%.py}"
    # echo from .$(basename $FILE) import \* >> $DST_DIR_P/$PYTHON_PACKAGE/__init__.py
    echo from .${FILE%.py} import \* >> $DST_DIR_P/$PYTHON_PACKAGE/__init__.py
done

