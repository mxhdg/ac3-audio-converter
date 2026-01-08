FROM scratch

# Place ONLY the mod directory in the image
COPY ac3convert.sh /mod/usr/local/bin/ac3convert
