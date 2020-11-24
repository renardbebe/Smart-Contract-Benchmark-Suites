 

 

pragma solidity >=0.4.21 <0.6.0;

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function transfer(address to, uint value, bytes memory data) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

 

pragma solidity >=0.4.21 <0.6.0;

contract ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity >=0.4.21 <0.6.0;




 

contract ERC223Token is ERC223Interface {
    using SafeMath for uint;

    mapping(address => uint) public balances;

     
    function transfer(address _to, uint _value, bytes memory _data) public {
         
         
        uint codeLength;

         
        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
    }

     
    function transfer(address _to, uint _value) public {
        uint codeLength;
        bytes memory empty;
         
        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity >=0.4.21 <0.6.0;



contract CNTMToken is ERC223Token, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address mpAddress;

    modifier onlyMP {
        require(msg.sender == mpAddress);
        _;
    }

    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalSupply = 1000000000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    function setMarketPlaceAddress(
        address _mpaddress
    ) public onlyOwner {
        mpAddress = _mpaddress;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyMP {
        uint codeLength;

         
        assembly {
            codeLength := extcodesize(_to)
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value, _data);
        }
        emit Transfer(_from, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) public onlyMP {
        uint codeLength;
        bytes memory empty;

         
        assembly {
            codeLength := extcodesize(_to)
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value, empty);
        }
        emit Transfer(_from, _to, _value);
    }
}