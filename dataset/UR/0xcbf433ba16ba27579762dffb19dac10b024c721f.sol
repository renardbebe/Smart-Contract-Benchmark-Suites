 

pragma solidity >=0.4.23 <0.6.0;

 
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

     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

contract ERC223 {
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transfer(address to, uint value, bytes memory data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);  
     
}

 
contract ERC223Token is ERC223 {
    using SafeMath for uint;

    mapping(address => uint256) balances;

    function transfer(address _to, uint _value) public returns (bool) {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > 0);
        require(msg.sender != _to);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
            return false;
        }

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value, bytes memory _data) public returns (bool) {
         
         
        uint codeLength;
        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > 0);
        require(msg.sender != _to);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            return false;
        }

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

 
 
 
 
contract Owned {
    address public owner;

    constructor() internal {
        owner = msg.sender;
        owner = 0x800A4B210B920020bE22668d28afd7ddef5c6243
;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
contract Grand is ERC223Token, Owned {
    string public constant name = "Grand Coin";
    string public constant symbol = "GRAND";
    uint8 public constant decimals = 18;

    uint256 public tokenRemained = 2 * (10 ** 9) * (10 ** uint(decimals));  
    uint256 public totalSupply = 2 * (10 ** 9) * (10 ** uint(decimals));

    bool public pause = false;

    mapping(address => bool) lockAddresses;

     
    constructor () public {
         
        balances[0x96F7F180C6B53e9313Dc26589739FDC8200a699f] = totalSupply;
    }

     
    function changeOwner(address _new) public onlyOwner {
    	require(_new != address(0));
        owner = _new;
    }

     
    function pauseContract() public onlyOwner {
        pause = true;
    }

    function resumeContract() public onlyOwner {
        pause = false;
    }

    function is_contract_paused() public view returns (bool) {
        return pause;
    }

     
    function lock(address _addr) public onlyOwner {
        lockAddresses[_addr] = true;
    }

    function unlock(address _addr) public onlyOwner {
        lockAddresses[_addr] = false;
    }

    function am_I_locked(address _addr) public view returns (bool) {
        return lockAddresses[_addr];
    }

     
    function() external payable {}

     
    function getETH(uint256 _amount) public onlyOwner {
        msg.sender.transfer(_amount);
    }

     
     
     
    modifier transferable(address _addr) {
        require(!pause);
        require(!lockAddresses[_addr]);
        _;
    }

    function transfer(address _to, uint _value, bytes memory _data) public transferable(msg.sender) returns (bool) {
        return super.transfer(_to, _value, _data);
    }

    function transfer(address _to, uint _value) public transferable(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
    function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
        return ERC20(_tokenAddress).transfer(owner, _value);
    }
}