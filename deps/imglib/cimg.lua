package.path = package.path .. ";../?.lua"
local ffi = require("ffi")

-- freom the freeimage .h file

ffi.cdef[[
typedef int32_t BOOL;

typedef int CIMG_IMAGE_FORMAT; 
enum CIMG_IMAGE_FORMAT {
	STBI_UNKNOWN = -1,
	STBI_BMP		= 0,
	STBI_ICO		= 1,
	STBI_JPEG	= 2,
	STBI_JNG		= 3,
	STBI_KOALA	= 4,
	STBI_LBM		= 5,
	STBI_IFF = STBI_LBM,
	STBI_MNG		= 6,
	STBI_PBM		= 7,
	STBI_PBMRAW	= 8,
	STBI_PCD		= 9,
	STBI_PCX		= 10,
	STBI_PGM		= 11,
	STBI_PGMRAW	= 12,
	STBI_PNG		= 13,
	STBI_PPM		= 14,
	STBI_PPMRAW	= 15,
	STBI_RAS		= 16,
	STBI_TARGA	= 17,
	STBI_TIFF	= 18,
	STBI_WBMP	= 19,
	STBI_PSD		= 20,
	STBI_CUT		= 21,
	STBI_XBM		= 22,
	STBI_XPM		= 23,
	STBI_DDS		= 24,
	STBI_GIF     = 25,
	STBI_HDR		= 26,
	STBI_FAXG3	= 27,
	STBI_SGI		= 28,
	STBI_EXR		= 29,
	STBI_J2K		= 30,
	STBI_JP2		= 31,
	STBI_PFM		= 32,
	STBI_PICT	= 33,
	STBI_RAW		= 34
};

typedef int CIMG_IMAGE_FILTER; 
enum CIMG_IMAGE_FILTER {
	FILTER_BOX		  = 0,	
	FILTER_BICUBIC	  = 1,	
	FILTER_BILINEAR   = 2,	
	FILTER_BSPLINE	  = 3,	
	FILTER_CATMULLROM = 4,	
	FILTER_LANCZOS3	  = 5	
};

typedef struct FIBITMAP FIBITMAP; struct FIBITMAP { void *data; };

typedef uint8_t BYTE;

typedef struct ImgObj
{
	void *  pixels;
	int		width;
	int		height;
	int		comp;
} ImgObj;

ImgObj * img_Load(const char *filename);
ImgObj * img_Scale(ImgObj * imgobj, int newwidth, int newheight);
void img_Save(ImgObj * imgobj, const char *filename, int nojpeg);
void img_Drop(ImgObj * imgobj);

]]

local img
if _G.PLATFORM.os == 'windows'then
    if _G.PLATFORM.arch == 'x86' then
        img = ffi.load("deps/imglib/cimg32.dll")
    else
        img = ffi.load("deps/imglib/cimg.dll")
    end
end
if _G.PLATFORM.os == 'linux' then
    img = ffi.load("deps/imglib/cimg.so")
end

function loadImage(filename)

    local textureFile = ffi.string(filename)
    local pixels = img.img_Load(textureFile)
    
    return {
        width=pixels.width,
        height=pixels.height,
        comp=pixels.comp,
        pixels=pixels
    }
end

function saveImage(filename, imgdata, nojpeg)
    local textureFile = ffi.string(filename)
    img.img_Save( imgdata.pixels, textureFile, nojpeg )
end

function dropImage(imgdata)

    img.img_Drop( imgdata.pixels )
end

function scaleImage(imgdata, newwidth, newheight)

    newpixels = img.img_Scale( imgdata.pixels, newwidth, newheight )
  
    return {
        width=newwidth,
        height=newheight,
        comp=newpixels.comp,
        pixels=newpixels
    }
end

return {
    img=img,
    loadImage=loadImage,
    saveImage=saveImage,
    scaleImage=scaleImage,
    dropImage=dropImage,
    STBI_BMP= 0,
	STBI_JPEG= 2,
	STBI_PNG= 13,
	STBI_GIF= 25,
}
