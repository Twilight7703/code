function varargout = main(action,varargin)
%MAIN Unified entry point for the telemedicine encryption workflow.
%   main('send',carrier,patientInfo,cipher,metadata,password)
%   main('verification_keygen',keyDirectory)
%   main('send_verification',carrier,patientInfo,cipher,metadata,logo,record,password,verifierSK,verifierPK)
%   main('verify_verification',cipher,metadata,logo,record,receiverRequest,verifierPK)
%   main('receive_verification',cipher,metadata,logo,record,receiverRequest,recoveredCarrier,recoveredInfo,password,verifierPK)
%   main('receive',cipher,metadata,recoveredCarrier,recoveredPatientInfo,password)

if nargin < 1
    error('An operation is required.');
end

switch lower(char(action))
    case 'send'
        if numel(varargin) ~= 5
            error('send requires 5 arguments.');
        end
        result = telemedicine_send(varargin{:});
        if nargout > 0, varargout{1} = result; end

    case {'verification_keygen','keygen_verification'}
        if numel(varargin) ~= 1
            error('verification_keygen requires a key directory.');
        end
        result = verification_generate_verifier_keys(varargin{:});
        if nargout > 0, varargout{1} = result; end

    case {'send_verification','verification_send'}
        if numel(varargin) < 9 || numel(varargin) > 11
            error('send_verification requires 9 to 11 arguments.');
        end
        [package,record,artifacts] = telemedicine_send_verification(varargin{:});
        if nargout > 0, varargout{1} = package; end
        if nargout > 1, varargout{2} = record; end
        if nargout > 2, varargout{3} = artifacts; end

    case {'verify','verify_verification','verification_verify'}
        if numel(varargin) ~= 6
            error('verify_verification requires 6 arguments.');
        end
        [result,detail] = verify_package(varargin{:});
        if nargout > 0, varargout{1} = result; end
        if nargout > 1, varargout{2} = detail; end

    case {'verification_request','request_verification'}
        if numel(varargin) < 1 || numel(varargin) > 2
            error('verification_request accepts one logo path and an optional character position list.');
        end
        result = verification_build_receiver_request(varargin{:});
        if nargout > 0, varargout{1} = result; end

    case 'receive'
        if numel(varargin) ~= 5
            error('receive requires 5 arguments.');
        end
        [carrier,patientInfo] = telemedicine_receive(varargin{:});
        if nargout > 0, varargout{1} = carrier; end
        if nargout > 1, varargout{2} = patientInfo; end

    case {'receive_verification','verification_receive'}
        if numel(varargin) ~= 9
            error('receive_verification requires 9 arguments.');
        end
        [carrier,patientInfo,detail] = telemedicine_receive_verification(varargin{:});
        if nargout > 0, varargout{1} = carrier; end
        if nargout > 1, varargout{2} = patientInfo; end
        if nargout > 2, varargout{3} = detail; end

    otherwise
        error('Unknown operation: %s.',char(action));
end
end
