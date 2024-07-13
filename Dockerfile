FROM debian:bullseye-slim AS builder
# install dependencies
RUN apt-get update && \
   apt-get install -y upx-ucl git zlib1g-dev gcc binutils make g++ autoconf automake

RUN git clone https://github.com/bwa-mem2/bwa-mem2 && \
   cd bwa-mem2 && \
   git submodule init && \
   git submodule update && \
   sed -i '/CXXFLAGS/s/$/ -static-libgcc -static-libstdc++/' Makefile && \
   sed -i '/LDFLAGS/s/$/ -static -lpthread -lz -ldl/' Makefile  && \  
   make -j && \
   upx bwa-mem2.avx && \
   upx bwa-mem2.avx2 && \
   upx bwa-mem2.sse41 && \
   upx bwa-mem2.sse42 && \
   upx bwa-mem2.avx512bw


 

FROM gcr.io/distroless/base

COPY --from=builder /bwa-mem2/bwa-mem2 /usr/local/bin/
COPY --from=builder /bwa-mem2/bwa-mem2.avx /usr/local/bin/
COPY --from=builder /bwa-mem2/bwa-mem2.avx2 /usr/local/bin/
COPY --from=builder /bwa-mem2/bwa-mem2.sse41 /usr/local/bin/
COPY --from=builder /bwa-mem2/bwa-mem2.sse42 /usr/local/bin/
COPY --from=builder /bwa-mem2/bwa-mem2.avx512bw /usr/local/bin/




ENTRYPOINT ["/usr/local/bin/bwa-mem2"]/
