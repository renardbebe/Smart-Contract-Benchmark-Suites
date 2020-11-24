 

pragma solidity ^0.5.10;

import "./controllable.sol";
import "./transferrable.sol";
import "./bytesUtils.sol";
import "./strings.sol";
import "./SafeMath.sol";

 
interface ITokenWhitelist {
    function getTokenInfo(address) external view returns (string memory, uint256, uint256, bool, bool, bool, uint256);
    function getStablecoinInfo() external view returns (string memory, uint256, uint256, bool, bool, bool, uint256);
    function tokenAddressArray() external view returns (address[] memory);
    function redeemableTokens() external view returns (address[] memory);
    function methodIdWhitelist(bytes4) external view returns (bool);
    function getERC20RecipientAndAmount(address, bytes calldata) external view returns (address, uint);
    function stablecoin() external view returns (address);
    function updateTokenRate(address, uint, uint) external;
}


 
contract TokenWhitelist is ENSResolvable, Controllable, Transferrable {
    using strings for *;
    using SafeMath for uint256;
    using BytesUtils for bytes;

    event UpdatedTokenRate(address _sender, address _token, uint _rate);

    event UpdatedTokenLoadable(address _sender, address _token, bool _loadable);
    event UpdatedTokenRedeemable(address _sender, address _token, bool _redeemable);

    event AddedToken(address _sender, address _token, string _symbol, uint _magnitude, bool _loadable, bool _redeemable);
    event RemovedToken(address _sender, address _token);

    event AddedMethodId(bytes4 _methodId);
    event RemovedMethodId(bytes4 _methodId);
    event AddedExclusiveMethod(address _token, bytes4 _methodId);
    event RemovedExclusiveMethod(address _token, bytes4 _methodId);

    event Claimed(address _to, address _asset, uint _amount);

     
    bytes4 private constant _APPROVE = 0x095ea7b3;  
    bytes4 private constant _BURN = 0x42966c68;  
    bytes4 private constant _TRANSFER= 0xa9059cbb;  
    bytes4 private constant _TRANSFER_FROM = 0x23b872dd;  

    struct Token {
        string symbol;     
        uint magnitude;    
        uint rate;         
        bool available;    
        bool loadable;     
        bool redeemable;     
        uint lastUpdate;   
    }

    mapping(address => Token) private _tokenInfoMap;

     
    mapping(bytes4 => bool) private _methodIdWhitelist;

    address[] private _tokenAddressArray;

     
    uint private _redeemableCounter;

     
    address private _stablecoin;

     
    bytes32 private _oracleNode;

     
     
     
     
     
    constructor(address _ens_, bytes32 _oracleNode_, bytes32 _controllerNode_, address _stablecoinAddress_) ENSResolvable(_ens_) Controllable(_controllerNode_) public {
        _oracleNode = _oracleNode_;
        _stablecoin = _stablecoinAddress_;
         
        _methodIdWhitelist[_APPROVE] = true;
        _methodIdWhitelist[_BURN] = true;
        _methodIdWhitelist[_TRANSFER] = true;
        _methodIdWhitelist[_TRANSFER_FROM] = true;
    }

    modifier onlyAdminOrOracle() {
        address oracleAddress = _ensResolve(_oracleNode);
        require (_isAdmin(msg.sender) || msg.sender == oracleAddress, "either oracle or admin");
        _;
    }

     
     
     
     
     
     
     
    function addTokens(address[] calldata _tokens, bytes32[] calldata _symbols, uint[] calldata _magnitude, bool[] calldata _loadable, bool[] calldata _redeemable, uint _lastUpdate) external onlyAdmin {
         
        require(_tokens.length == _symbols.length && _tokens.length == _magnitude.length && _tokens.length == _loadable.length && _tokens.length == _loadable.length, "parameter lengths do not match");
         
        for (uint i = 0; i < _tokens.length; i++) {
             
            require(!_tokenInfoMap[_tokens[i]].available, "token already available");
             
            string memory symbol = _symbols[i].toSliceB32().toString();
             
            _tokenInfoMap[_tokens[i]] = Token({
                symbol : symbol,
                magnitude : _magnitude[i],
                rate : 0,
                available : true,
                loadable : _loadable[i],
                redeemable: _redeemable[i],
                lastUpdate : _lastUpdate
                });
             
            _tokenAddressArray.push(_tokens[i]);
             
            if (_redeemable[i]){
                _redeemableCounter = _redeemableCounter.add(1);
            }
             
            emit AddedToken(msg.sender, _tokens[i], symbol, _magnitude[i], _loadable[i], _redeemable[i]);
        }
    }

     
     
    function removeTokens(address[] calldata _tokens) external onlyAdmin {
         
        for (uint i = 0; i < _tokens.length; i++) {
             
            address token = _tokens[i];
             
            require(_tokenInfoMap[token].available, "token is not available");
             
            if (_tokenInfoMap[token].redeemable){
                _redeemableCounter = _redeemableCounter.sub(1);
            }
             
            delete _tokenInfoMap[token];
             
            for (uint j = 0; j < _tokenAddressArray.length.sub(1); j++) {
                if (_tokenAddressArray[j] == token) {
                    _tokenAddressArray[j] = _tokenAddressArray[_tokenAddressArray.length.sub(1)];
                    break;
                }
            }
            _tokenAddressArray.length--;
             
            emit RemovedToken(msg.sender, token);
        }
    }

     
     
    function getERC20RecipientAndAmount(address _token, bytes calldata _data) external view returns (address, uint) {
         
         
        require(_data.length >= 4 + 32, "not enough method-encoding bytes");
         
        bytes4 signature = _data._bytesToBytes4(0);
         
        require(isERC20MethodSupported(_token, signature), "unsupported method");
         
        if (signature == _BURN) {
             
            return (_token, _data._bytesToUint256(4));
        } else if (signature == _TRANSFER_FROM) {
             
            require(_data.length >= 4 + 32 + 32 + 32, "not enough data for transferFrom");
            return ( _data._bytesToAddress(4 + 32 + 12), _data._bytesToUint256(4 + 32 + 32));
        } else {  
             
            require(_data.length >= 4 + 32 + 32, "not enough data for transfer/appprove");
            return (_data._bytesToAddress(4 + 12), _data._bytesToUint256(4 + 32));
        }
    }

     
    function setTokenLoadable(address _token, bool _loadable) external onlyAdmin {
         
        require(_tokenInfoMap[_token].available, "token is not available");

         
        _tokenInfoMap[_token].loadable = _loadable;

        emit UpdatedTokenLoadable(msg.sender, _token, _loadable);
    }

     
    function setTokenRedeemable(address _token, bool _redeemable) external onlyAdmin {
         
        require(_tokenInfoMap[_token].available, "token is not available");

         
        _tokenInfoMap[_token].redeemable = _redeemable;

        emit UpdatedTokenRedeemable(msg.sender, _token, _redeemable);
    }

     
     
     
     
    function updateTokenRate(address _token, uint _rate, uint _updateDate) external onlyAdminOrOracle {
         
        require(_tokenInfoMap[_token].available, "token is not available");
         
        _tokenInfoMap[_token].rate = _rate;
         
        _tokenInfoMap[_token].lastUpdate = _updateDate;
         
        emit UpdatedTokenRate(msg.sender, _token, _rate);
    }

     
    function claim(address payable _to, address _asset, uint _amount) external onlyAdmin {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }

     
     
     
     
     
     
     
     
     
    function getTokenInfo(address _a) external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        Token storage tokenInfo = _tokenInfoMap[_a];
        return (tokenInfo.symbol, tokenInfo.magnitude, tokenInfo.rate, tokenInfo.available, tokenInfo.loadable, tokenInfo.redeemable, tokenInfo.lastUpdate);
    }

     
     
     
     
     
     
     
     
    function getStablecoinInfo() external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        Token storage stablecoinInfo = _tokenInfoMap[_stablecoin];
        return (stablecoinInfo.symbol, stablecoinInfo.magnitude, stablecoinInfo.rate, stablecoinInfo.available, stablecoinInfo.loadable, stablecoinInfo.redeemable, stablecoinInfo.lastUpdate);
    }

     
     
    function tokenAddressArray() external view returns (address[] memory) {
        return _tokenAddressArray;
    }

     
     
    function redeemableTokens() external view returns (address[] memory) {
        address[] memory redeemableAddresses = new address[](_redeemableCounter);
        uint redeemableIndex = 0;
        for (uint i = 0; i < _tokenAddressArray.length; i++) {
            address token = _tokenAddressArray[i];
            if (_tokenInfoMap[token].redeemable){
                redeemableAddresses[redeemableIndex] = token;
                redeemableIndex += 1;
            }
        }
        return redeemableAddresses;
    }


     
     
    function isERC20MethodSupported(address _token, bytes4 _methodId) public view returns (bool) {
        require(_tokenInfoMap[_token].available, "non-existing token");
        return (_methodIdWhitelist[_methodId]);
    }

     
     
    function isERC20MethodWhitelisted(bytes4 _methodId) external view returns (bool) {
        return (_methodIdWhitelist[_methodId]);
    }

     
     
    function redeemableCounter() external view returns (uint) {
        return _redeemableCounter;
    }

     
     
    function stablecoin() external view returns (address) {
        return _stablecoin;
    }

     
     
    function oracleNode() external view returns (bytes32) {
        return _oracleNode;
    }
}
