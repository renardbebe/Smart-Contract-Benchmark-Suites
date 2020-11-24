 

pragma solidity ^0.4.19;

 
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



contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



  function Ownable() internal {
    owner = msg.sender;
  }



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }



  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
 
 
 
 


contract Lescovex is Ownable {
  uint256 public totalSupply;
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping(address => uint256) holded;

  event Transfer(address indexed from, address indexed to, uint256 value);

 event Approval(address indexed owner, address indexed spender, uint256 value);


  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(block.timestamp>blockEndICO || msg.sender==owner);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    holded[_to]=block.number;
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;

    
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function holdedOf(address _owner) public view returns (uint256 balance) {
    return holded[_owner];
  }

  mapping (address => mapping (address => uint256)) internal allowed;


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    holded[_to]=block.number;
    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  function burn(address addr) public onlyOwner{
    balances[addr]=0;
  }

  function approve(address _spender, uint256 _value) public onlyOwner returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }


  function increaseApproval(address _spender, uint _addedValue) public onlyOwner returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(address _spender, uint _subtractedValue) public onlyOwner returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

    string public constant standard = "ERC20 Lescovex";

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 8;  

     
    uint256 public constant minPrice = 7500000000000000;
    uint256 public constant blockEndICO = 1524182460;
    uint256 public buyPrice = minPrice;

    uint256 constant initialSupply=0;
    string constant tokenName="Lescovex Shareholder's";
    string constant tokenSymbol="LCX";

    uint256 public tokenReward = 0;
     
    uint256 public tokenUnit = uint256(10)**decimals;
    
     
     
    address public LescovexAddr = 0xD26286eb9E6E623dba88Ed504b628F648ADF7a0E;

     
    event LogDeposit(address sender, uint amount);

     
    function Lescovex() public {
       
        totalSupply = initialSupply;   
        name = tokenName;              
        symbol = tokenSymbol;          
    }

    function () public payable {
        buy();    
    }
    

    modifier status() {
        _;   

    if(block.timestamp<1519862460){  
      if(totalSupply<50000000000000){
        buyPrice=7500000000000000;
      }else{
        buyPrice=8000000000000000;
      }
  
    }else if(block.timestamp<1520640060){  

      buyPrice=8000000000000000;
    }else if(block.timestamp<1521504060){  

      buyPrice=8500000000000000;
    }else if(block.timestamp<1522368060){  

      buyPrice=9000000000000000;

    }else if(block.timestamp<1523232060){  
      buyPrice=9500000000000000;

    }else{

      buyPrice=10000000000000000;
    }

        
    }

    function deposit() public payable status returns(bool success) {
         
        assert (this.balance + msg.value >= this.balance);  
      tokenReward=this.balance/totalSupply;
         
        LogDeposit(msg.sender, msg.value);
        
        return true;
    }

  function withdrawReward() public status {
    require (block.number - holded[msg.sender] > 172800);  
    
    holded[msg.sender] = block.number;
    uint256 ethAmount = tokenReward * balances[msg.sender];

     
    msg.sender.transfer(ethAmount);
      
     
    LogWithdrawal(msg.sender, ethAmount);
  }


  event LogWithdrawal(address receiver, uint amount);
  
  function withdraw(uint value) public onlyOwner {
     
    msg.sender.transfer(value);
     
    LogWithdrawal(msg.sender, value);
  }


    function transferBuy(address _to, uint256 _value) internal returns (bool) {
      require(_to != address(0));
      

       

      totalSupply=totalSupply.add(_value*2);
      holded[_to]=block.number;
      balances[LescovexAddr] = balances[LescovexAddr].add(_value);
      balances[_to] = balances[_to].add(_value);

      Transfer(this, _to, _value);
      return true;
      
    }

  
           
    function buy() public payable status{
     
      require (totalSupply<=1000000000000000);
      require(block.timestamp<blockEndICO);

      uint256 tokenAmount = (msg.value / buyPrice)*tokenUnit ;   

      transferBuy(msg.sender, tokenAmount);
      LescovexAddr.transfer(msg.value);
    
    }


     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner returns (bool success) {    

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public ; 
}