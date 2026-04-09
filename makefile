# CatBrowser Universal Makefile (macOS 12 to 15+)
# Supports Intel (x86_64) and Apple Silicon (arm64)

CXX = clang++
CXXFLAGS = -std=c++11 -Wall -ObjC++
DEFINES = -DWEBVIEW_COCOA -DOBJC_OLD_DISPATCH_PROTOTYPES=1
FRAMEWORKS = -framework WebKit -framework Cocoa -framework AppKit

# Target macOS 12 and build for both chip types
ARCH_FLAGS = -arch x86_64 -arch arm64 -mmacosx-version-min=12.0

TARGET = CatBrowser
SRC = main.mm

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(DEFINES) $(ARCH_FLAGS) $(SRC) $(FRAMEWORKS) -o $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean