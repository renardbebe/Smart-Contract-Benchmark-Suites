 

pragma solidity ^0.4.11;

 
     
    library SafeMath {
      function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
      }

      function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
      }

      function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
      }

      function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    }

     
    contract ERC20Basic {
      uint256 public totalSupply;
      function balanceOf(address who) constant returns (uint256);
      function transfer(address to, uint256 value) returns (bool);
      event Transfer(address indexed from, address indexed to, uint256 value);
    }

     
    contract ERC20 is ERC20Basic {
      function allowance(address owner, address spender) constant returns (uint256);
      function transferFrom(address from, address to, uint256 value) returns (bool);
      function approve(address spender, uint256 value) returns (bool);
      event Approval(address indexed owner, address indexed spender, uint256 value);
    }

     
    contract BasicToken is ERC20Basic {
      using SafeMath for uint256;

      mapping(address => uint256) balances;

       
      function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
      }

       
      function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
      }

    }

     
    contract StandardToken is ERC20, BasicToken {

      mapping (address => mapping (address => uint256)) allowed;


       
      function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
      }

       
      function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
      }

       
      function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
      }
      
       
      function increaseApproval (address _spender, uint _addedValue) 
        returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }

      function decreaseApproval (address _spender, uint _subtractedValue) 
        returns (bool success) {
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

     
    contract Ownable {
      address public owner;


      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


       
      function Ownable() {
        owner = msg.sender;
      }


       
      modifier onlyOwner() {
        require(msg.sender == owner);
        _;
      }


       
      function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));      
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
      }

    }
 

contract RewardToken is StandardToken, Ownable {
    bool public payments = false;
    mapping(address => uint256) public rewards;
    uint public payment_time = 0;
    uint public payment_amount = 0;

    event Reward(address indexed to, uint256 value);

    function payment() payable onlyOwner {
        require(payments);
        require(msg.value >= 0.01 * 1 ether);

        payment_time = now;
        payment_amount = this.balance;
    }

    function _reward(address _to) private returns (bool) {
        require(payments);
        require(rewards[_to] < payment_time);

        if(balances[_to] > 0) {
			uint amount = payment_amount * balances[_to] / totalSupply;

			require(_to.send(amount));

			Reward(_to, amount);
		}

        rewards[_to] = payment_time;

        return true;
    }

    function reward() returns (bool) {
        return _reward(msg.sender);
    }

    function transfer(address _to, uint256 _value) returns (bool) {
		if(payments) {
			if(rewards[msg.sender] < payment_time) require(_reward(msg.sender));
			if(rewards[_to] < payment_time) require(_reward(_to));
		}

        return super.transfer(_to, _value);
    }

	function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
		if(payments) {
			if(rewards[_from] < payment_time) require(_reward(_from));
			if(rewards[_to] < payment_time) require(_reward(_to));
		}

        return super.transferFrom(_from, _to, _value);
    }
}

contract LoriToken is RewardToken {
    using SafeMath for uint;

    string public name = "LORI Invest Token";
    string public symbol = "LORI";
    uint256 public decimals = 18;

    bool public mintingFinished = false;
    bool public commandGetBonus = false;
    uint public commandGetBonusTime = 1543932000;        

    event Mint(address indexed holder, uint256 tokenAmount);
    event MintFinished();
    event MintCommandBonus();

    function _mint(address _to, uint256 _amount) onlyOwner private returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);

        return true;
    }

    function mint(address _to, uint256 _amount) onlyOwner returns(bool) {
        require(!mintingFinished);
        return _mint(_to, _amount);
    }

    function finishMinting() onlyOwner returns(bool) {
        mintingFinished = true;
        payments = true;

        MintFinished();

        return true;
    }

    function commandMintBonus(address _to) onlyOwner {
        require(mintingFinished && !commandGetBonus);
        require(now > commandGetBonusTime);

        commandGetBonus = true;

        require(_mint(_to, totalSupply * 5 / 100));

        MintCommandBonus();
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint;

    LoriToken public token;
    address public beneficiary = 0xdA6273CBF8DFB22f4A55A6F87bb1A91C57e578db;

    uint public collected;

    uint public preICOstartTime = 1507644000;      
    uint public preICOendTime = 1508853600;      
    uint public ICOstartTime = 1510322400;     
    uint public ICOendTime = 1512396000;        
    bool public crowdsaleFinished = false;

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    function Crowdsale() {
        token = new LoriToken();
    }

    function() payable {
        doPurchase();
    }

    function doPurchase() payable {
        assert((now > preICOstartTime && now < preICOendTime) || (now > ICOstartTime && now < ICOendTime));
        require(msg.value >= 0.01 * 1 ether);
        require(!crowdsaleFinished);

        uint tokens = msg.value * (now >= ICOstartTime ? 100 : 120);

        require(token.mint(msg.sender, tokens));
        require(beneficiary.send(msg.value));

        collected = collected.add(msg.value);

        NewContribution(msg.sender, tokens, msg.value);
    }

    function withdraw() onlyOwner {
        require(token.finishMinting());
        require(beneficiary.send(this.balance));
        token.transferOwnership(beneficiary);

        crowdsaleFinished = true;
    }
}