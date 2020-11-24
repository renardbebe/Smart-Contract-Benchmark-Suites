 

pragma solidity ^0.4.21;

contract EIP20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;

  function Owanble() public{
    owner = msg.sender;
  }

   
   

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
   
   

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Haltable is Ownable {
  bool public halted = false;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract TokenSale is Haltable {
    using SafeMath for uint;

    string public name = "TokenSale Contract";

     
    EIP20Interface public token;
    address public beneficiary;
    address public reserve;
    uint public price = 0;  

     
    uint public tokensSoldTotal = 0;  
    uint public weiRaisedTotal = 0;  
    uint public investorCount = 0;

    event NewContribution(
        address indexed holder,
        uint256 tokenAmount,
        uint256 etherAmount);

    function TokenSale(
        ) public {
            
         
        owner = msg.sender;
        
         
        token = EIP20Interface(address(0x2F7823AaF1ad1dF0D5716E8F18e1764579F4ABe6));
        
         
        beneficiary = address(0xf2b9DA535e8B8eF8aab29956823df7237f1863A3);
        
         
        reserve = address(0x966c0FD16a4f4292E6E0372e04fbB5c7013AD02e);
        
         
        price = 0.00379 ether;
    }

    function changeBeneficiary(address _beneficiary) public onlyOwner stopInEmergency {
        beneficiary = _beneficiary;
    }
    
    function changeReserve(address _reserve) public onlyOwner stopInEmergency {
        reserve = _reserve;
    }
    
    function changePrice(uint _price) public onlyOwner stopInEmergency {
        price = _price;
    }

    function () public payable stopInEmergency {
        
         
        require(msg.value >= price);
        
         
        uint tokens = msg.value / price;
        
         
        require(token.balanceOf(this) >= tokens);
        
         
        tokensSoldTotal = tokensSoldTotal.add(tokens);
        if (token.balanceOf(msg.sender) == 0) investorCount++;
        weiRaisedTotal = weiRaisedTotal.add(msg.value);
        
         
        token.transfer(msg.sender, tokens);

         
        uint reservePie = msg.value.div(10);
        
         
        uint beneficiaryPie = msg.value.sub(reservePie);

         
        reserve.transfer(reservePie);

         
        beneficiary.transfer(beneficiaryPie);

        emit NewContribution(msg.sender, tokens, msg.value);
    }
    
    
     
     
    function withdrawERC20Token(address _token) public onlyOwner stopInEmergency {
        ERC20 foreignToken = ERC20(_token);
        foreignToken.transfer(msg.sender, foreignToken.balanceOf(this));
    }
    
     
     
    function withdrawEIP20Token(address _token) public onlyOwner stopInEmergency {
        EIP20Interface foreignToken = EIP20Interface(_token);
        foreignToken.transfer(msg.sender, foreignToken.balanceOf(this));
    }
    
     
     
    function withdrawToken() public onlyOwner stopInEmergency {
        token.transfer(msg.sender, token.balanceOf(this));
    }
    
     
    function tokensRemaining() public constant returns (uint256) {
        return token.balanceOf(this);
    }
    
}