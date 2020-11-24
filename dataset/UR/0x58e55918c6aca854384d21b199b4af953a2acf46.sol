 

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


 
 
 
 
 

contract BagholderERC20 is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) held;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 public constant blockEndICO = 1525197600;

     
    string public constant standard = "ERC20 Bagholder";
    uint8 public constant decimals = 8;  
    uint256 public totalSupply;
    string public name;
    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function heldOf(address _owner) public view returns (uint256 balance) {
        return held[_owner];
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(block.timestamp > blockEndICO || msg.sender == owner);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        held[_to] = block.number;
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        held[_to] = block.number;
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        Transfer(_from, _to, _value);
        return true;
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

    
contract Bagholder is BagholderERC20 {

     
    uint256 constant initialSupply = 0;
    string constant tokenName = "Bagholder";
    string constant tokenSymbol = "BAG";

    address public BagholderAddr = 0x02cEE5441eFb50C1532a53F3EAA1E074621174F2;
    uint256 public constant minPrice = 75000000000000;   
    uint256 public buyPrice = minPrice;
    uint256 public tokenReward = 0;
     
    uint256 public tokenUnit = uint256(10)**decimals;

     
    event LogDeposit(address sender, uint amount);
    event LogWithdrawal(address receiver, uint amount);
  
     
    function Bagholder() public {
        totalSupply = initialSupply;   
        name = tokenName;              
        symbol = tokenSymbol;          
    }

    function () public payable {
        buy();    
    }

    modifier status() {
        _;   

        if (block.timestamp < 1520272800){           
            if (totalSupply < 50000000000000){
                buyPrice = 75000000000000;

            } else {			 
                buyPrice = 80000000000000;
            }
        } else if (block.timestamp < 1521136800){    
          buyPrice = 80000000000000;

        } else if (block.timestamp<1522605600){      
          buyPrice = 85000000000000;

        } else if (block.timestamp < 1523815200){    

          buyPrice = 90000000000000;	


        } else {

          buyPrice = 100000000000000; 
        }
    }

    function deposit() public payable onlyOwner returns(bool success) {
         

        assert (this.balance + msg.value >= this.balance);  
        tokenReward = this.balance / totalSupply;

         
        LogDeposit(msg.sender, msg.value);
        
        return true;
    }

    function withdrawReward() public status {
        require (block.number - held[msg.sender] > 172800);  

        held[msg.sender] = block.number;
        uint256 ethAmount = tokenReward * balances[msg.sender];

         
        msg.sender.transfer(ethAmount);
          
         
        LogWithdrawal(msg.sender, ethAmount);
    }

    function withdraw(uint value) public onlyOwner {
         
        msg.sender.transfer(value);

         
        LogWithdrawal(msg.sender, value);
    }

    function buy() public payable status {
        require (totalSupply <= 10000000000000000);
        require(block.timestamp < blockEndICO);

        uint256 tokenAmount = (msg.value / buyPrice)*tokenUnit ;   

        transferBuy(msg.sender, tokenAmount);
        BagholderAddr.transfer(msg.value);
    }

    function transferBuy(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));

         
        totalSupply = totalSupply.add(_value*2);
        held[_to] = block.number;
        balances[BagholderAddr] = balances[BagholderAddr].add(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(this, _to, _value);
        Transfer(this, BagholderAddr, _value);
        return true;
    }

  function burn(address addr) public onlyOwner{
    totalSupply=totalSupply.sub(balances[addr]);
    balances[addr]=0;

  }

}