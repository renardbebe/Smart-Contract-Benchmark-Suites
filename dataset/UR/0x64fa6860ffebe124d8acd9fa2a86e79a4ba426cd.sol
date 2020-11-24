 

pragma solidity ^0.4.13;

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


     
    function Ownable() public {
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract TripsCoin is StandardToken, Ownable {
    using SafeMath for uint;

    string constant public symbol = "TIC";
    string constant public name = "TripsCoin";

    uint8 constant public decimals = 18;

    uint constant ITSStartTime = 1527782400; 	 
    uint public ITSEndTime = 1536425999; 		 
    uint constant unlockTime = 1546272000; 		 

    uint public airdropTime = 1527609600;  		 
    uint public airdropAmount = 128e18;

    uint public publicsaleTokens = 700000000e18;
    uint public companyTokens = 150000000e18;
    uint public teamTokens = 70000000e18;
    uint public privatesaleTokens = 50000000e18;
    uint public airdropSupply = 30000000e18;

    address publicsale = 0xb0361E2FC9b553107BB16BeAec9dCB6D7353db87;
    address company = 0xB5572E2A8f8A568EeF03e787021e9f696d7Ddd6A;
    address team = 0xf0922aBf47f5D9899eaE9377780f75E05cD25672;
    address privatesale = 0x6bc55Fa50A763E0d56ea2B4c72c45aBfE9Ed38d7;
	address beneficiary = 0x4CFeb9017EA4eaFFDB391a0B9f20Eb054e456338;
    mapping(address => bool) initialized;

    event Burn(address indexed burner, uint256 value);


    function TripsCoin() public {
        owner = msg.sender;
        totalSupply_ = 1000000000e18;

         
        preSale(company, companyTokens);
        preSale(team, teamTokens);
        preSale(publicsale, publicsaleTokens);
        preSale(privatesale, privatesaleTokens);
    }

    function preSale(address _address, uint _amount) internal returns (bool) {
        balances[_address] = _amount;
        Transfer(address(0x0), _address, _amount);
    }

    function checkPermissions(address _from) internal constant returns (bool) {

        if (_from == team && now < unlockTime) {
            return false;
        }

        if (_from == publicsale || _from == company || _from == privatesale) {
            return true;
        }

        if (now < ITSEndTime) {
            return false;
        } else {
            return true;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(msg.sender));
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(_from));
        super.transferFrom(_from, _to, _value);
    }

     function () payable {
             issueToken();
     }

     function issueToken() payable {

       if (!beneficiary.send(msg.value)) {
           throw;
       }

       require(balances[msg.sender] == 0);
       require(airdropSupply >= airdropAmount);
       require(!initialized[msg.sender]);
       require(now > airdropTime);

       balances[msg.sender] = balances[msg.sender].add(airdropAmount);
       airdropSupply = airdropSupply.sub(airdropAmount);
       initialized[msg.sender] = true;
     }
      
     function burn(uint256 _value) public onlyOwner{
         require(_value <= balances[msg.sender]);
          
          

         address burner = msg.sender;
         balances[burner] = balances[burner].sub(_value);
         totalSupply_ = totalSupply_.sub(_value);
         totalSupply_ = totalSupply_.sub(airdropSupply);
         _value = _value.add(airdropSupply);
         Burn(burner, _value);
     }
}