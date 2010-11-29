function om_save_sparse(data,filename,format)

% OM_SAVE_SPARSE   Save sparse Matrix
%
%   Save sparse Matrix
%
%   SYNTAX
%       OM_SAVE_SPARSE(DATA,FILENAME,FORMAT)
%
%       FORMAT : can be 'ascii' or 'binary' (default)
%

me = 'OM_SAVE_SPARSE';

if nargin == 0
    eval(['help ',lower(me)])
    return
end

if nargin < 3
    format = 'mat';
end

dims = size(data);
[ii,jj,vv] = find(data);
ii = ii - 1;
jj = jj - 1;

switch format
    case 'mat'
        file = fopen(filename,'w');
        data_raw=struct('matrix',data);
        save(filename,'-MAT','-struct','data_raw','-v73')
        fclose(file);
        clear data_raw;
    case 'binary'
        disp(['Saving file ',filename])
        file = fopen(filename,'w');
        fwrite(file,dims,'uint32','ieee-le');
        for ll=1:length(ii)
            fwrite(file,ii(ll),'uint32','ieee-le');
            fwrite(file,jj(ll),'uint32','ieee-le');
            fwrite(file,vv(ll),'double','ieee-le');
        end
        fclose(file);
    case 'ascii'
        dlmwrite(filename, dims, 'delimiter', '\t','precision','%d')
        data = double([ii jj vv]);
        dlmwrite(filename, data, '-append', 'delimiter', '\t','precision',18)
    otherwise
        error([me,' : Unknown file format'])
end

