 

pragma solidity ^0.4.21;


 
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



 

contract Token77G is Claimable, StandardToken {

    string constant public name = "GraphenTech";
    string constant public symbol = "77G";
    uint8 constant public decimals = 18;  

    uint256 public graphenRestrictedDate;
     
    mapping (address => uint256) private restrictedTokens;
     
    address[] private addList;
    address private icoadd;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

      
    function Token77G(
    address _team,
    address _reserve,
    address _advisors,
    uint _deadLine
    )
    public
    {

        icoadd = msg.sender;
        totalSupply_ = (19000000000) * 10 ** uint256(decimals);

        balances[_reserve] = balances[_reserve].add((1890500000) * 10 ** uint256(decimals));
        addAddress(_reserve);
        emit Transfer(icoadd, _reserve, (1890500000) * 10 ** uint256(decimals));

        allocateTokens(_team, (1330000000) * 10 ** uint256(decimals));
        emit Transfer(icoadd, _team, (1330000000) * 10 ** uint256(decimals));

        balances[_advisors] = balances[_advisors].add((950000000) * 10 ** uint256(decimals));
        addAddress(_advisors);
        emit Transfer(icoadd, _advisors, (950000000) * 10 ** uint256(decimals));

        balances[icoadd] = (14829500000) * 10 **uint256(decimals);
        graphenRestrictedDate = _deadLine;

    }

     
    function restrictedTokensOf(address _add) public view returns(uint restrctedTokens) {
        return restrictedTokens[_add];
    }

     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256  tmpRestrictedDate;

        if (restrictedTokens[msg.sender] > 0) {
            require((now < tmpRestrictedDate && _value <= (balances[msg.sender].sub(restrictedTokens[msg.sender])))||now >= tmpRestrictedDate); 
        }
        if (balances[_to] == 0) addAddress(_to);
        _transfer(_to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        uint256 tmpRestrictedDate;

        if (restrictedTokens[msg.sender] > 0) {
            require((now < tmpRestrictedDate && _value <= (balances[msg.sender]-restrictedTokens[msg.sender]))||now >= tmpRestrictedDate); 
        }

        if (balances[_to] == 0)addAddress(_to);
        super.transferFrom(_from, _to, _value);
        return true;

    }
      
     
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] = balances[msg.sender].sub(_value);             
        totalSupply_ = totalSupply_.sub(_value);                       
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, 0x0, _value);
        return true;
    }

      
    function getAddressFromList(uint256 _index)public view  returns (address add) {
        require(_index < addList.length);
        return addList[_index];
    }

      
    function getAddListSize()public view  returns (uint) {
        return addList.length;
    }

      
    function allocateTokens(address _add, uint256 _value) private {
        balances[_add] = balances[_add].add(_value);
        restrictedTokens[_add] = restrictedTokens[_add].add(_value);
        addAddress(_add);
    }

      
    function _transfer(address _to, uint256 _value) private {
         
        require(_to != 0x0);
         
        require(balances[msg.sender] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint256 previousBalances = balances[msg.sender].add(balances[_to]);
         
        balances[msg.sender] = balances[msg.sender].sub(_value); 
         
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
         
        assert(balances[msg.sender] + balances[_to] == previousBalances);
    }

    
    function addAddress(address _add) private {
        addList.push(_add);
    }


}


 

contract ICO_Graphene is Claimable {

    using SafeMath for uint256;

     
    uint256 public availablePrivateICO;
     
    uint256 public availablePreICO;
     
    uint256 public availableICO_w1;
     
    uint256 public availableICO_w2;

     
    uint256 public availableICO;

     
    uint256 public amountRaised;
     
    uint256 public tokensSold;
     
    uint256 private decimals;

     
    uint256 public startPrivateICO = 1528329600;  
     
    uint256 public endPrivateICO = 1532649599;  

     
    uint256 public startPreICO = 1532649600;  
     
    uint256 public endPreICO = 1535327999;  

     
    uint256 public startICO_w1 = 1535328000;  
     
    uint256 public endICO_w1 = 1538006399;  

     
    uint256 public startICO_w2 = 1538006400;  
     
    uint256 public endICO_w2 = 1540684799;  

     
    enum StatusList { NotStarted, Running, Waiting, Closed, Paused}
     
    StatusList public status;
     
    enum StagesList { N_A, PrivateICO, PreICO, ICO_w1, ICO_w2}
     
    StagesList public stage;
     
    uint256[5] private tokenPrice;
     
    Token77G private tokenReward;

     
     
    uint256 public restrictedTokensDate = 1550447999;  

     
    address public tokenAdd;

     
    mapping(address => uint256) public purchaseMap;
     
     

     

     
    address constant private TOKENSRESERVE = 0xA89779a50b3540677495e12eA09f02B6Bf09803F;
    address constant private TEAM = 0x39E545F03d26334d735815Bb9882423cE46d8326;
    address constant private ADVISORS = 0x96DFaBbD575C48d82e5bCC92f64E0349Da60712a;

     
    address constant private SALARIES = 0x99330754059f1348296526a52AA4F787a7648B46;
    address constant private MARKETINGandBUSINESS = 0x824663D62c22f2592c5a3DC37638C09907adE7Ec;
    address constant private RESEARCHandDEVELOPMENT = 0x7156023Cd4579Eb6a7A171062A44574809B353C8;
    address constant private RESERVE = 0xAE55c485Fe70Ce6E547A30f5F4b28F32D9c1c093;
    address constant private FACTORIES = 0x30CF1d5F0c561118fA017f15B86f914ef5C078e6;
    address constant private PLANEQUIPMENT = 0xC74c83d8eC7c6233715b0aD8Ba4da8f72301fA24;
    address constant private PRODUCTION = 0xEa0553a23469cb7140190d443762d70664a36343;


     
    event Purchase(address _from, uint _amount, uint _tokens);

     
    modifier onlyInState (StatusList _status) {
        require(_status == status);
        _;
    }

     
    modifier onlyIfNotPaused() {
        require(status != StatusList.Paused);
        _;
    }

      
    function ICO_Graphene() public {

        tokenReward = new Token77G(TEAM, TOKENSRESERVE, ADVISORS, restrictedTokensDate);

        tokenAdd = tokenReward;
        decimals = tokenReward.decimals();
        status = StatusList.NotStarted;
        stage = StagesList.N_A;
        amountRaised = 0;
        tokensSold = 0;

        availablePrivateICO = (1729000000) * 10 ** uint256(decimals);
        availablePreICO = (3325000000) * 10 ** uint256(decimals);
        availableICO_w1 = (5120500000) * 10 ** uint256(decimals);
        availableICO_w2 = (4655000000) * 10 ** uint256(decimals);

        tokenPrice = [0, 13860000000000, 14850000000000, 17820000000000, 19800000000000];

    }

      
    function () public payable onlyIfNotPaused {
        updateStatus();
        if (stage == StagesList.PrivateICO) {
            require(msg.value >= 1000000000000000000 wei);
        }
        _transfer();
        updateStatusViaTokens();
    }

       
    function kill()
    external onlyOwner onlyInState(StatusList.Closed) {
        selfdestruct(owner);
    }

     
    function pause() public onlyOwner {
        updateStatus();
        require(status != StatusList.Closed);
        status = StatusList.Paused;
    }

     
    function unpause() public onlyOwner onlyInState(StatusList.Paused) {
        updateStatus();
        updateStatusViaTokens();
    }

     
    function setNewICOTime(
    uint _startPrivateICO,
    uint _endPrivateICO,
    uint _startPreICO,
    uint _endPreICO,
    uint _startICO_w1,
    uint _endICO_w1,
    uint _startICO_w2,
    uint _endICO_w2
    )
    public
    onlyOwner onlyInState(StatusList.NotStarted) {
        require(now < startPrivateICO && startPrivateICO < endPrivateICO && startPreICO < endPreICO && startICO_w1 < endICO_w1 && startICO_w2 < endICO_w2);  
        startPrivateICO = _startPrivateICO;
        endPrivateICO = _endPrivateICO;
        startPreICO = _startPreICO;
        endPreICO = _endPreICO;
        startICO_w1 = _startICO_w1;
        endICO_w1 = _endICO_w1;
        startICO_w2 = _startICO_w2;
        endICO_w2 = _endICO_w2;
    }

     
     function closeICO() public onlyOwner {
        updateStatus();
        require(status == StatusList.Closed);
        transferExcessTokensToReserve();
    }

    function transferExcessTokensToReserve() internal {
      availableICO = tokenReward.balanceOf(this);
      if (availableICO > 0) {
        tokenReward.transfer(TOKENSRESERVE, availableICO);
      }
    }

     
    function updateStatus() internal {
        if (now >= endICO_w2) { 
            status = StatusList.Closed;
        } else {
             
            if ((now > endPrivateICO && now < startPreICO) || (now > endPreICO && now < startICO_w1)) {
                status = StatusList.Waiting;
            } else {
                if (now < startPrivateICO) { 
                    status = StatusList.NotStarted;
                } else {
                    status = StatusList.Running;
                    updateStages();
                }
            }
        }
    }

     
    function updateStatusViaTokens() internal {
        availableICO = tokenReward.balanceOf(this);
        if (availablePrivateICO == 0 && stage == StagesList.PrivateICO) status = StatusList.Waiting;
        if (availablePreICO == 0 && stage == StagesList.PreICO) status = StatusList.Waiting;
        if (availableICO_w1 == 0 && stage == StagesList.ICO_w1) status = StatusList.Waiting;
        if (availableICO_w2 == 0 && stage == StagesList.ICO_w2) status = StatusList.Waiting;
        if (availableICO == 0) status = StatusList.Closed;
    }

     
    function updateStages() internal onlyInState(StatusList.Running) {
        if (now <= endPrivateICO && now > startPrivateICO) { stage = StagesList.PrivateICO; return;} 
        if (now <= endPreICO && now > startPreICO) { stage = StagesList.PreICO; return;} 
        if (now <= endICO_w1 && now > startICO_w1) { stage = StagesList.ICO_w1; return;} 
        if (now <= endICO_w2 && now > startICO_w2) { stage = StagesList.ICO_w2; return;} 
        stage = StagesList.N_A;
    }

      
    function _transfer() private onlyInState(StatusList.Running) {
        uint amount = msg.value;
        uint amountToReturn = 0;
        uint tokens = 0;
        (tokens, amountToReturn) = getTokens(amount);
        purchaseMap[msg.sender] = purchaseMap[msg.sender].add(amount);
        tokensSold = tokensSold.add(tokens);
        amount = amount.sub(amountToReturn);
        amountRaised = amountRaised.add(amount);
        if (stage == StagesList.PrivateICO) availablePrivateICO = availablePrivateICO.sub(tokens);
        if (stage == StagesList.PreICO) availablePreICO = availablePreICO.sub(tokens);
        if (stage == StagesList.ICO_w1) availableICO_w1 = availableICO_w1.sub(tokens);
        if (stage == StagesList.ICO_w2) availableICO_w2 = availableICO_w2.sub(tokens);
        tokenReward.transfer(msg.sender, tokens);
        sendETH(amount);

        if (amountToReturn > 0) {
            bool refound = msg.sender.send(amountToReturn);
            require(refound);
        }

        emit Purchase(msg.sender, amount, tokens);
    }

      
    function getTokens(uint256 _value)
    private view
    onlyInState(StatusList.Running)
    returns(uint256 numTokens, uint256 amountToReturn) {

        uint256 eths = _value.mul(10**decimals); 
        numTokens = 0;
        uint256 tokensAvailable = 0;
        numTokens = eths.div(tokenPrice[uint256(stage)]);

        if (stage == StagesList.PrivateICO) {
            tokensAvailable = availablePrivateICO;
        } else if (stage == StagesList.PreICO) {
            tokensAvailable = availablePreICO;
        } else if (stage == StagesList.ICO_w1) {
            tokensAvailable = availableICO_w1;
        } else if (stage == StagesList.ICO_w2) {
            tokensAvailable = availableICO_w2;
        }

        if (tokensAvailable >= numTokens) {
            amountToReturn = 0;
        } else {
            numTokens = tokensAvailable;
            amountToReturn = _value.sub(numTokens.div(10**decimals).mul(tokenPrice[uint256(stage)]));
        }

        return (numTokens, amountToReturn);
    }

     
    function sendETH(uint _amount)  private {

        uint paymentSALARIES = _amount.mul(3).div(100);
        uint paymentMARKETINGandBUSINESS = _amount.mul(4).div(100);
        uint paymentRESEARCHandDEVELOPMENT = _amount.mul(14).div(100);
        uint paymentRESERVE = _amount.mul(18).div(100);
        uint paymentFACTORIES = _amount.mul(24).div(100);
        uint paymentPLANEQUIPMENT = _amount.mul(19).div(100);
        uint paymentPRODUCTION = _amount.mul(18).div(100);

        SALARIES.transfer(paymentSALARIES);
        MARKETINGandBUSINESS.transfer(paymentMARKETINGandBUSINESS);
        RESEARCHandDEVELOPMENT.transfer(paymentRESEARCHandDEVELOPMENT);
        RESERVE.transfer(paymentRESERVE);
        FACTORIES.transfer(paymentFACTORIES);
        PLANEQUIPMENT.transfer(paymentPLANEQUIPMENT);
        PRODUCTION.transfer(paymentPRODUCTION);

    }

}