 

pragma solidity ^0.4.23;


 
contract SignatureVerifier {

    function splitSignature(bytes sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
         
            r := mload(add(sig, 32))
         
            s := mload(add(sig, 64))
         
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

     
    function verifyString(
        string message,
        uint8 v,
        bytes32 r,
        bytes32 s)
    internal pure
    returns (address signer) {

         
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;

        assembly {
         
            length := mload(message)
         
            lengthOffset := add(header, 57)
        }

         
        require(length <= 999999);
         
        uint256 lengthLength = 0;
         
        uint256 divisor = 100000;
         

        while (divisor != 0) {
             
            uint256 digit = length / divisor;
            if (digit == 0) {
                 
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
             
            lengthLength++;
             
            length -= digit * divisor;
             
            divisor /= 10;

             
            digit += 0x30;
             
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
         
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
         
        assembly {
            mstore(header, lengthLength)
        }
         
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract AccessControl is SignatureVerifier {
    using SafeMath for uint256;

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public systemAddress;
    uint256 public CLevelTxCount_ = 0;

     
    mapping(address => uint256) nonces;

     
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    modifier onlySystem() {
        require(msg.sender == systemAddress);
        _;
    }

    function recover(bytes32 hash, bytes sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
         
        if (sig.length != 65) {
            return (address(0));
        }
         
        (v, r, s) = splitSignature(sig);
         
        if (v < 27) {
            v += 27;
        }
         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            return ecrecover(prefixedHash, v, r, s);
        }
    }

    function signedCLevel(
        bytes32 _message,
        bytes _sig
    )
    internal
    view
    onlyCLevel
    returns (bool)
    {
        address signer = recover(_message, _sig);

        require(signer != msg.sender);
        return (
        signer == cooAddress ||
        signer == ceoAddress ||
        signer == cfoAddress
        );
    }

    event addressLogger(address signer);

     
    function getCEOHashing(address _newCEO, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0F3E), _newCEO, _nonce));
    }

     
     
    function setCEO(
        address _newCEO,
        bytes _sig
    ) external onlyCLevel {
        require(
            _newCEO != address(0) &&
            _newCEO != cfoAddress &&
            _newCEO != cooAddress
        );

        bytes32 hashedTx = getCEOHashing(_newCEO, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        ceoAddress = _newCEO;
        CLevelTxCount_++;
    }

     
    function getCFOHashing(address _newCFO, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0F01), _newCFO, _nonce));
    }

     
     
    function setCFO(
        address _newCFO,
        bytes _sig
    ) external onlyCLevel {
        require(
            _newCFO != address(0) &&
            _newCFO != ceoAddress &&
            _newCFO != cooAddress
        );

        bytes32 hashedTx = getCFOHashing(_newCFO, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        cfoAddress = _newCFO;
        CLevelTxCount_++;
    }

     
    function getCOOHashing(address _newCOO, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0F02), _newCOO, _nonce));
    }

     
     
    function setCOO(
        address _newCOO,
        bytes _sig
    ) external onlyCLevel {
        require(
            _newCOO != address(0) &&
            _newCOO != ceoAddress &&
            _newCOO != cfoAddress
        );

        bytes32 hashedTx = getCOOHashing(_newCOO, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        cooAddress = _newCOO;
        CLevelTxCount_++;
    }

    function getNonce() external view returns (uint256) {
        return nonces[msg.sender];
    }
}


interface ERC20 {
    function transfer(address _to, uint _value) external returns (bool success);

    function balanceOf(address who) external view returns (uint256);
}

contract SaleToken is AccessControl {
    using SafeMath for uint256;

     
    event BuyDeklaSuccessful(uint256 dekla, address buyer);
    event UpdateDeklaPriceSuccessful(uint256 price, address sender);
    event WithdrawEthSuccessful(address sender, uint256 amount);
    event WithdrawDeklaSuccessful(address sender, uint256 amount);
    event UpdateMinimumPurchaseAmountSuccessful(address sender, uint256 percent);

     
     
    uint256 public deklaTokenPrice = 22590000000000;

    uint256 public decimals = 18;

     
    uint256 public minimumPurchaseAmount;

     
    mapping(address => uint256) nonces;

    address public systemAddress;

     
    ERC20 public token;

    constructor(
        address _ceoAddress,
        address _cfoAddress,
        address _cooAddress,
        address _systemAddress
    ) public {
         
        ceoAddress = _ceoAddress;
        cfoAddress = _cfoAddress;
        cooAddress = _cooAddress;
        systemAddress = _systemAddress;
        minimumPurchaseAmount = 50 * (10 ** decimals);
    }

     
    modifier validToken() {
        require(token != address(0));
        _;
    }

    modifier onlySystem() {
        require(msg.sender == systemAddress);
        _;
    }

    function recover(bytes32 hash, bytes sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
         
        if (sig.length != 65) {
            return (address(0));
        }
         
        (v, r, s) = splitSignature(sig);
         
        if (v < 27) {
            v += 27;
        }
         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            return ecrecover(prefixedHash, v, r, s);
        }
    }

    function getNonces(address _sender) public view returns (uint256) {
        return nonces[_sender];
    }

    function setDeklaPrice(uint256 _price) external onlySystem {
        deklaTokenPrice = _price;
        emit UpdateDeklaPriceSuccessful(_price, msg.sender);
    }

    function setMinimumPurchaseAmount(uint256 _price) external onlySystem {
        minimumPurchaseAmount = _price;
        emit UpdateMinimumPurchaseAmountSuccessful(msg.sender, _price);
    }

    function getTokenAddressHashing(address _token, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E30), _token, _nonce));
    }

    function setTokenAddress(address _token, bytes _sig) external onlyCLevel {
        bytes32 hashedTx = getTokenAddressHashing(_token, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        token = ERC20(_token);
    }

     
    function calculateDekla(uint256 _value) external view returns (uint256) {
        require(_value >= deklaTokenPrice);
        return _value.div(deklaTokenPrice);
    }

     
     
    function() external payable validToken {
         
        uint256 amount = msg.value.div(deklaTokenPrice) * (10 ** decimals);

         
        require(amount >= minimumPurchaseAmount);

         
        require(token.balanceOf(this) >= amount);

        token.transfer(msg.sender, amount);
        emit BuyDeklaSuccessful(amount, msg.sender);
    }

     
     
     
    function withdrawEthHashing(address _address, uint256 _amount, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E32), _address, _amount, _nonce));
    }

     
     
     
    function withdrawEth(address _withdrawWallet, uint256 _amount, bytes _sig) external onlyCLevel {
        bytes32 hashedTx = withdrawEthHashing(_withdrawWallet, _amount, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        uint256 balance = address(this).balance;

         
        require(balance > 0);

         
        require(balance >= _amount);

        _withdrawWallet.transfer(_amount);
        emit WithdrawEthSuccessful(_withdrawWallet, _amount);
    }

     
     
     
    function withdrawDeklaHashing(address _address, uint256 _amount, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0E33), _address, _amount, _nonce));
    }

     
     
     
    function withdrawDekla(address _withdrawWallet, uint256 _amount, bytes _sig) external validToken onlyCLevel {
        bytes32 hashedTx = withdrawDeklaHashing(_withdrawWallet, _amount, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        uint256 balance = token.balanceOf(this);

         
        require(balance > 0);

         
        require(balance >= _amount);

         
        token.transfer(_withdrawWallet, _amount);
        emit WithdrawDeklaSuccessful(_withdrawWallet, _amount);
    }
}