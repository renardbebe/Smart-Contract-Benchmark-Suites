 

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

 

 
contract DeklaAccessControl is SignatureVerifier {
    using SafeMath for uint256;

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
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
        return keccak256(abi.encodePacked(bytes4(0x486A0F3F), _newCFO, _nonce));
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
        return keccak256(abi.encodePacked(bytes4(0x486A0F40), _newCOO, _nonce));
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


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC865 is ERC20Basic {
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool);

    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool);

    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool);

    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool);

    function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool);
}

 
contract BasicToken is ERC20Basic, DeklaAccessControl {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    uint256 mintTxCount_ = 1;
    uint256 public teamRate = 20;
    uint256 public saleRate = 80;

     
    address public saleAddress;
    address public teamAddress;
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
    public
    returns (bool) {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


 
contract ERC865Token is ERC865, StandardToken {
     
     

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

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

    function recoverSigner(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    view
    returns (address)
    {
        require(_to != address(0));
         
        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        return from;
    }


    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool)
    {
        require(_to != address(0));
         
        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);
         
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }
     
    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool)
    {
        require(_spender != address(0));
         
        bytes32 hashedTx = approvePreSignedHashing(address(this), _spender, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        allowed[from][_spender] = _value;
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);
         
        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }

     
    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool)
    {
        require(_spender != address(0));
         
        bytes32 hashedTx = increaseApprovalPreSignedHashing(address(this), _spender, _addedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        allowed[from][_spender] = allowed[from][_spender].add(_addedValue);
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);
         
        emit Approval(from, _spender, allowed[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

     
    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool)
    {
        require(_spender != address(0));
         
        bytes32 hashedTx = decreaseApprovalPreSignedHashing(address(this), _spender, _subtractedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        uint oldValue = allowed[from][_spender];
        if (_subtractedValue > oldValue) {
            allowed[from][_spender] = 0;
        } else {
            allowed[from][_spender] = oldValue.sub(_subtractedValue);
        }
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);
         
        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

     
    function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    returns (bool)
    {
        require(_to != address(0));
         
        bytes32 hashedTx = transferFromPreSignedHashing(address(this), _from, _to, _value, _fee, _nonce);
        address spender = recover(hashedTx, _signature);
        require(spender != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][spender] = allowed[_from][spender].sub(_value);
        balances[spender] = balances[spender].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);
         
        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }

     
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    pure
    returns (bytes32)
    {
         
        return keccak256(abi.encodePacked(bytes4(0x486A0F41), _token, _to, _value, _fee, _nonce));
    }
     
    function approvePreSignedHashing(
        address _token,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_token, _spender, _value, _fee, _nonce));
    }
     
    function increaseApprovalPreSignedHashing(
        address _token,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
    public
    pure
    returns (bytes32)
    {
         
        return keccak256(abi.encodePacked(bytes4(0x486A0F42), _token, _spender, _addedValue, _fee, _nonce));
    }
     
    function decreaseApprovalPreSignedHashing(
        address _token,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
    public
    pure
    returns (bytes32)
    {
         
        return keccak256(abi.encodePacked(bytes4(0x486A0F43), _token, _spender, _subtractedValue, _fee, _nonce));
    }
     
    function transferFromPreSignedHashing(
        address _token,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
    public
    pure
    returns (bytes32)
    {
         
        return keccak256(abi.encodePacked(bytes4(0x486A0F44), _token, _from, _to, _value, _fee, _nonce));
    }
}

 

contract MintableToken is ERC865Token {
    using SafeMath for uint256;

    event Mint(address indexed to, uint256 amount);

     
    uint256 public constant totalTokenLimit = 10000000000000000000000000000;

     
    uint256 public maxTokenRateToMint = 20;
    uint256 public canMintLimit = 0;


     
    modifier canMint()
    {

         
        require(
            teamAddress != address(0) &&
            saleAddress != address(0)

        );

         
        require(totalSupply_ <= totalTokenLimit);
        require(balances[saleAddress] <= canMintLimit);
        _;
    }


     
    function mint() onlyCLevel external {
        _mint(1000000000000000000000000000);
    }

    function _mint(uint256 _amount)
    canMint
    internal
    {
        uint256 saleAmount_ = _amount.mul(saleRate).div(100);
        uint256 teamAmount_ = _amount.mul(teamRate).div(100);

        totalSupply_ = totalSupply_.add(_amount);
        balances[saleAddress] = balances[saleAddress].add(saleAmount_);
        balances[teamAddress] = balances[teamAddress].add(teamAmount_);

        canMintLimit = balances[saleAddress]
        .mul(maxTokenRateToMint)
        .div(100);
        mintTxCount_++;

        emit Mint(saleAddress, saleAmount_);
        emit Mint(teamAddress, teamAmount_);
    }

    function getMaxTokenRateToMintHashing(uint256 _rate, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0F45), _rate, _nonce));
    }

    function setMaxTokenRateToMint(
        uint256 _rate,
        bytes _sig
    ) external onlyCLevel {
        require(_rate <= 100);
        require(_rate >= 0);

        bytes32 hashedTx = getMaxTokenRateToMintHashing(_rate, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        maxTokenRateToMint = _rate;
        CLevelTxCount_++;
    }

    function getMintRatesHashing(uint256 _saleRate, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes4(0x486A0F46), _saleRate, _nonce));
    }

    function setMintRates(
        uint256 saleRate_,
        bytes _sig
    )
    external
    onlyCLevel
    {
        require(saleRate.add(teamRate) == 100);
        require(mintTxCount_ >= 3);

        bytes32 hashedTx = getMintRatesHashing(saleRate_, nonces[msg.sender]);
        require(signedCLevel(hashedTx, _sig));
        nonces[msg.sender]++;

        saleRate = saleRate_;
        CLevelTxCount_++;
    }
}


contract DeklaToken is MintableToken {
    string public name = "Dekla Token";
    string public symbol = "DKL";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 1000000000 * (10 ** decimals);

    function isDeklaToken() public pure returns (bool){
        return true;
    }

    constructor (
        address _ceoAddress,
        address _cfoAddress,
        address _cooAddress,
        address _teamAddress,
        address _saleAddress
    ) public {
         
        teamAddress = _teamAddress;

         
        ceoAddress = _ceoAddress;
        cfoAddress = _cfoAddress;
        cooAddress = _cooAddress;
        saleAddress = _saleAddress;

         
        _mint(INITIAL_SUPPLY);
    }
}