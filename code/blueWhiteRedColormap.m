function blueWhiteRed = blueWhiteRedColormap()
%BLUEWHITEREDCOLORMAP Returns a colormap that is blue on the low end, white
%in the center, and red on the high end

blueToWhite = repmat([0 0 1],100,1) + repmat([1 1 0],100,1).*(linspace(0,1,100)');
whiteToRed = repmat([1 0 0],100,1) + repmat([0 1 1],100,1).*(linspace(1,0,100)');
blueWhiteRed = [blueToWhite;whiteToRed];

end