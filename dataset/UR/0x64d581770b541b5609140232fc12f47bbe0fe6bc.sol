 

pragma solidity ^0.4.17;

 
contract BaseToken {
     

     
    uint256 public totalSupply;

     
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
}


  

 
contract ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}


 
contract StandardToken is BaseToken {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
     
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}


contract Moneto is StandardToken {
  
  string public name = "Moneto";
  string public symbol = "MTO";
  uint8 public decimals = 18;

  function Moneto(address saleAddress) public {
    require(saleAddress != 0x0);

    totalSupply = 42901786 * 10**18;
    balances[saleAddress] = totalSupply;
    emit Transfer(0x0, saleAddress, totalSupply);

    assert(totalSupply == balances[saleAddress]);
  }

  function burn(uint num) public {
    require(num > 0);
    require(balances[msg.sender] >= num);
    require(totalSupply >= num);

    uint preBalance = balances[msg.sender];

    balances[msg.sender] -= num;
    totalSupply -= num;
    emit Transfer(msg.sender, 0x0, num);

    assert(balances[msg.sender] == preBalance - num);
  }
}


contract MonetoSale {
    Moneto public token;

    address public beneficiary;
    address public alfatokenteam;
    uint public alfatokenFee;
    
    uint public amountRaised;
    uint public tokenSold;
    
    uint public constant PRE_SALE_START = 1523952000;  
    uint public constant PRE_SALE_END = 1526543999;  
    uint public constant SALE_START = 1528617600;  
    uint public constant SALE_END = 1531209599;  

    uint public constant PRE_SALE_MAX_CAP = 2531250 * 10**18;
    uint public constant SALE_MAX_CAP = 300312502 * 10**17;

    uint public constant SALE_MIN_CAP = 2500 ether;

    uint public constant PRE_SALE_PRICE = 1250;
    uint public constant SALE_PRICE = 1000;

    uint public constant PRE_SALE_MIN_BUY = 10 * 10**18;
    uint public constant SALE_MIN_BUY = 1 * 10**18;

    uint public constant PRE_SALE_1WEEK_BONUS = 35;
    uint public constant PRE_SALE_2WEEK_BONUS = 15;
    uint public constant PRE_SALE_3WEEK_BONUS = 5;
    uint public constant PRE_SALE_4WEEK_BONUS = 0;

    uint public constant SALE_1WEEK_BONUS = 10;
    uint public constant SALE_2WEEK_BONUS = 7;
    uint public constant SALE_3WEEK_BONUS = 5;
    uint public constant SALE_4WEEK_BONUS = 3;
    
    mapping (address => uint) public icoBuyers;

    Stages public stage;
    
    enum Stages {
        Deployed,
        Ready,
        Ended,
        Canceled
    }
    
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    function MonetoSale(address _beneficiary, address _alfatokenteam) public {
        beneficiary = _beneficiary;
        alfatokenteam = _alfatokenteam;
        alfatokenFee = 5 ether;

        stage = Stages.Deployed;
    }

    function setup(address _token) public isOwner atStage(Stages.Deployed) {
        require(_token != 0x0);
        token = Moneto(_token);

        stage = Stages.Ready;
    }

    function () payable public atStage(Stages.Ready) {
        require((now >= PRE_SALE_START && now <= PRE_SALE_END) || (now >= SALE_START && now <= SALE_END));

        uint amount = msg.value;
        amountRaised += amount;

        if (now >= SALE_START && now <= SALE_END) {
            assert(icoBuyers[msg.sender] + msg.value >= msg.value);
            icoBuyers[msg.sender] += amount;
        }
        
        uint tokenAmount = amount * getPrice();
        require(tokenAmount > getMinimumAmount());
        uint allTokens = tokenAmount + getBonus(tokenAmount);
        tokenSold += allTokens;

        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            require(tokenSold <= PRE_SALE_MAX_CAP);
        }
        if (now >= SALE_START && now <= SALE_END) {
            require(tokenSold <= SALE_MAX_CAP);
        }

        token.transfer(msg.sender, allTokens);
    }

    function transferEther(address _to, uint _amount) public isOwner {
        require(_amount <= address(this).balance - alfatokenFee);
        require(now < SALE_START || stage == Stages.Ended);
        
        _to.transfer(_amount);
    }

    function transferFee(address _to, uint _amount) public {
        require(msg.sender == alfatokenteam);
        require(_amount <= alfatokenFee);

        alfatokenFee -= _amount;
        _to.transfer(_amount);
    }

    function endSale(address _to) public isOwner {
        require(amountRaised >= SALE_MIN_CAP);

        token.transfer(_to, tokenSold*3/7);
        token.burn(token.balanceOf(address(this)));

        stage = Stages.Ended;
    }

    function cancelSale() public {
        require(amountRaised < SALE_MIN_CAP);
        require(now > SALE_END);

        stage = Stages.Canceled;
    }

    function takeEtherBack() public atStage(Stages.Canceled) returns (bool) {
        return proxyTakeEtherBack(msg.sender);
    }

    function proxyTakeEtherBack(address receiverAddress) public atStage(Stages.Canceled) returns (bool) {
        require(receiverAddress != 0x0);
        
        if (icoBuyers[receiverAddress] == 0) {
            return false;
        }

        uint amount = icoBuyers[receiverAddress];
        icoBuyers[receiverAddress] = 0;
        receiverAddress.transfer(amount);

        assert(icoBuyers[receiverAddress] == 0);
        return true;
    }

    function getBonus(uint amount) public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            uint w = now - PRE_SALE_START;
            if (w <= 1 weeks) {
                return amount * PRE_SALE_1WEEK_BONUS/100;
            }
            if (w > 1 weeks && w <= 2 weeks) {
                return amount * PRE_SALE_2WEEK_BONUS/100;
            }
            if (w > 2 weeks && w <= 3 weeks) {
                return amount * PRE_SALE_3WEEK_BONUS/100;
            }
            if (w > 3 weeks && w <= 4 weeks) {
                return amount * PRE_SALE_4WEEK_BONUS/100;
            }
            return 0;
        }
        if (now >= SALE_START && now <= SALE_END) {
            uint w2 = now - SALE_START;
            if (w2 <= 1 weeks) {
                return amount * SALE_1WEEK_BONUS/100;
            }
            if (w2 > 1 weeks && w2 <= 2 weeks) {
                return amount * SALE_2WEEK_BONUS/100;
            }
            if (w2 > 2 weeks && w2 <= 3 weeks) {
                return amount * SALE_3WEEK_BONUS/100;
            }
            if (w2 > 3 weeks && w2 <= 4 weeks) {
                return amount * SALE_4WEEK_BONUS/100;
            }
            return 0;
        }
        return 0;
    }

    function getPrice() public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_PRICE;
        }
        if (now >= SALE_START && now <= SALE_END) {
            return SALE_PRICE;
        }
        return 0;
    }

    function getMinimumAmount() public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_MIN_BUY;
        }
        if (now >= SALE_START && now <= SALE_END) {
            return SALE_MIN_BUY;
        }
        return 0;
    }
}