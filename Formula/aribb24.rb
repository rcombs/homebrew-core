class Aribb24 < Formula
  desc "Library for decoding ARIB STD-B24 caption streams"
  homepage "https://github.com/nkoriyama/aribb24"
  url "https://github.com/nkoriyama/aribb24/archive/v1.0.3.tar.gz"
  sha256 "f61560738926e57f9173510389634d8c06cabedfa857db4b28fb7704707ff128"

  head do
    url "https://github.com/nkoriyama/aribb24.git"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "libpng"

  def install
    system "autoreconf", "-i"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <aribb24/aribb24.h>
      #include <aribb24/parser.h>

      int main()
      {
        const char test_str[] = \
          "\\x80\\xff\\xf0\\x04\\x00\\x00\\x00\\x4e\\x3f\\x00\\x00\\x4a\\x1f\\x20\\x00\\x00"
          "\\x01\\x0c\\x1f\\x20\\x00\\x00\\x3f\\x9b\\x37\\x20\\x53\\x9b\\x31\\x37\\x30\\x3b"
          "\\x33\\x30\\x20\\x5f\\x9b\\x36\\x32\\x30\\x3b\\x34\\x38\\x30\\x20\\x56\\x1d\\x61"
          "\\x9b\\x33\\x36\\x3b\\x33\\x36\\x20\\x57\\x9b\\x34\\x20\\x58\\x9b\\x32\\x34\\x20"
          "\\x59\\x8a\\x87\\x90\\x20\\x44\\x90\\x51\\x9b\\x31\\x37\\x30\\x3b\\x33\\x32\\x39"
          "\\x20\\x61\\x7d\\x7a\\x21\\x41\\x9a\\xdf";

        arib_instance_t *instance = arib_instance_new(NULL);
        if (!instance)
          return 1;
        arib_parser_t *parser = arib_get_parser(instance);
        if (!parser)
          return 1;

        arib_parse_pes(parser, test_str, sizeof(test_str) - 1);

        size_t parsed_size = 0;
        const char *parsed = arib_parser_get_data(parser, &parsed_size);

        if (!parsed || !parsed_size)
          return 1;

        arib_decoder_t *decoder = arib_get_decoder(instance);
        if (!decoder)
          return 1;

        arib_initialize_decoder_a_profile(decoder);

        char decoded[256];
        size_t decoded_size = arib_decode_buffer(decoder, parsed, parsed_size, decoded, sizeof(decoded));

        if (strcmp(decoded, "\\xe2\\x99\\xac\\xe3\\x80\\x9c"))
          return 1;

        arib_finalize_decoder(decoder);

        arib_instance_destroy(instance);
        return 0;
      }
    EOS

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-laribb24", "-o", "test"
    system "./test"
  end
end
