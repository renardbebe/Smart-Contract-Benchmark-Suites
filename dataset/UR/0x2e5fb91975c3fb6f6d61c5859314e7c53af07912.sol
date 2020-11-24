 

pragma solidity 0.4.21;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract ERC820Implementer {
    ERC820Registry erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}
interface ERC777TokensSender {
    function tokensToSend(address operator, address from, address to, uint amount, bytes userData,bytes operatorData) external;
}


interface ERC777TokensRecipient {
    function tokensReceived(address operator, address from, address to, uint amount, bytes userData, bytes operatorData) external;
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function Ownable() public {
    setOwner(msg.sender);
  }

   
  function setOwner(address newOwner) internal {
    owner = newOwner;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    setOwner(newOwner);
  }
}

contract JaroCoinToken is Ownable, ERC820Implementer {
    using SafeMath for uint256;

    string public constant name = "JaroCoin";
    string public constant symbol = "JARO";
    uint8 public constant decimals = 18;
    uint256 public constant granularity = 1e10;    

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => bool)) public isOperatorFor;
    mapping (address => mapping (uint256 => bool)) private usedNonces;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes userData, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes userData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 0;
    uint256 public constant maxSupply = 21000000e18;


     

     
    function send(address _to, uint256 _amount, bytes _userData) public {
        doSend(msg.sender, _to, _amount, _userData, msg.sender, "", true);
    }

     
    function sendByCheque(address _to, uint256 _amount, bytes _userData, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) public {
        require(_to != address(this));

         
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(prefix, keccak256(_to, _amount, _userData, _nonce));
         

        address signer = ecrecover(hash, v, r, s);
        require (signer != 0);
        require (!usedNonces[signer][_nonce]);
        usedNonces[signer][_nonce] = true;

         
        doSend(signer, _to, _amount, _userData, signer, "", true);
    }

     
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        isOperatorFor[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

     
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        isOperatorFor[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

     
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor[msg.sender][_from]);
        doSend(_from, _to, _amount, _userData, msg.sender, _operatorData, true);
    }

     
     
    function requireMultiple(uint256 _amount) internal pure {
        require(_amount.div(granularity).mul(granularity) == _amount);
    }

     
    function isRegularAddress(address _addr) internal constant returns(bool) {
        if (_addr == 0) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) }  
        return size == 0;
    }

     
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData
    ) private {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation != 0) {
            ERC777TokensSender(senderImplementation).tokensToSend(
                _operator, _from, _to, _amount, _userData, _operatorData);
        }
    }

     
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    ) private {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to));
        }
    }

     
    function doSend(
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        address _operator,
        bytes _operatorData,
        bool _preventLocking
    )
        private
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != 0x0);                   
        require(balanceOf[_from] >= _amount);  

        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        emit Transfer(_from, _to, _amount);
    }

     

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        doSend(msg.sender, _to, _value, "", msg.sender, "", false);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isOperatorFor[msg.sender][_from]);
        doSend(_from, _to, _value, "", msg.sender, "", true);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 _amount) {
        if (isOperatorFor[_spender][_owner]) {
            _amount = balanceOf[_owner];
        } else {
            _amount = 0;
        }
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != msg.sender);

        if (_value > 0) {
             
            isOperatorFor[_spender][msg.sender] = true;
            emit AuthorizedOperator(_spender, msg.sender);
        } else {
             
            isOperatorFor[_spender][msg.sender] = false;
            emit RevokedOperator(_spender, msg.sender);
        }

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     

     
    function mint(address _to, uint256 _amount, bytes _operatorData) public onlyOwner {
        require (totalSupply.add(_amount) <= maxSupply);
        requireMultiple(_amount);

        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        callRecipient(msg.sender, 0x0, _to, _amount, "", _operatorData, true);

        emit Minted(msg.sender, _to, _amount, _operatorData);
        emit Transfer(0x0, _to, _amount);
    }

     
    function burn(uint256 _amount, bytes _userData) public {
        require (_amount > 0);
        require (balanceOf[msg.sender] >= _amount);
        requireMultiple(_amount);

        callSender(msg.sender, msg.sender, 0x0, _amount, _userData, "");

        totalSupply = totalSupply.sub(_amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);

        emit Burned(msg.sender, msg.sender, _amount, _userData, "");
        emit Transfer(msg.sender, 0x0, _amount);
    }

}