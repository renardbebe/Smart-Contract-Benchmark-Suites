 

pragma solidity ^0.4.23;

 

 
contract SafeMath {
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

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract Ownerable {
     
     
    modifier onlyOwner { require(msg.sender == owner); _; }

    address public owner;

    constructor() public { owner = msg.sender;}

     
     
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

 

 
contract KYC is Ownerable {
   
  mapping (address => bool) public registeredAddress;

   
  mapping (address => bool) public admin;

  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event NewAdmin(address indexed _addr);
  event ClaimedTokens(address _token, address owner, uint256 balance);

   
  modifier onlyRegistered(address _addr) {
    require(registeredAddress[_addr]);
    _;
  }

   
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }

  constructor () public {
    admin[msg.sender] = true;
  }

   
  function setAdmin(address _addr)
    public
    onlyOwner
  {
    require(_addr != address(0) && admin[_addr] == false);
    admin[_addr] = true;

    emit NewAdmin(_addr);
  }

   
  function register(address _addr)
    public
    onlyAdmin
  {
    require(_addr != address(0) && registeredAddress[_addr] == false);

    registeredAddress[_addr] = true;

    emit Registered(_addr);
  }

   
  function registerByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0) && registeredAddress[_addrs[i]] == false);

      registeredAddress[_addrs[i]] = true;

      emit Registered(_addrs[i]);
    }
  }

   
  function unregister(address _addr)
    public
    onlyAdmin
    onlyRegistered(_addr)
  {
    registeredAddress[_addr] = false;

    emit Unregistered(_addr);
  }

   
  function unregisterByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(registeredAddress[_addrs[i]]);

      registeredAddress[_addrs[i]] = false;

      emit Unregistered(_addrs[i]);
    }
  }

  function claimTokens(address _token) public onlyOwner {

    if (_token == 0x0) {
        owner.transfer( address(this).balance );
        return;
    }

    ERC20Basic token = ERC20Basic(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);

    emit ClaimedTokens(_token, owner, balance);
  }
}

 

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    constructor() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

 

 

 
 
 
 
 
 
 



contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            require (allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           uint previousBalanceFrom = balanceOfAt(_from, block.number);
           require(previousBalanceFrom >= _amount);
            
            
            

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           uint previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           emit Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        emit NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(0, _owner, _amount);
        return true;
    }

     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }
    
     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer( address(this).balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

 

contract HEX is MiniMeToken {
    mapping (address => bool) public blacklisted;
    bool public generateFinished;

    constructor (address _tokenFactory)
        MiniMeToken(
              _tokenFactory,
              0x0,                      
              0,                        
              "Health Evolution on X.blockchain",   
              18,                       
              "HEX",                    
              false                      
          ) {
    }

    function generateTokens(address _holder, uint _amount) public onlyController returns (bool) {
        require(generateFinished == false);
        return super.generateTokens(_holder, _amount);
    }

    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        require(blacklisted[_from] == false);
        return super.doTransfer(_from, _to, _amount);
    }

    function finishGenerating() public onlyController returns (bool) {
        generateFinished = true;
        return true;
    }

    function blacklistAccount(address tokenOwner) public onlyController returns (bool success) {
        blacklisted[tokenOwner] = true;
        return true;
    }

    function unBlacklistAccount(address tokenOwner) public onlyController returns (bool success) {
        blacklisted[tokenOwner] = false;
        return true;
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer( address(this).balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(controller, balance);

        emit ClaimedTokens(_token, controller, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}

 

contract ATXICOToken {
    function atxBuy(address _from, uint256 _amount) public returns(bool);
}

 

contract HEXCrowdSale is Ownerable, SafeMath, ATXICOToken {
  uint256 public maxHEXCap;
  uint256 public minHEXCap;

  uint256 public ethRate;
  uint256 public atxRate;
   

  address[] public ethInvestors;
  mapping (address => uint256) public ethInvestorFunds;

  address[] public atxInvestors;
  mapping (address => uint256) public atxInvestorFunds;

  address[] public atxChangeAddrs;
  mapping (address => uint256) public atxChanges;

  KYC public kyc;
  HEX public hexToken;
  address public hexControllerAddr;
  ERC20Basic public atxToken;
  address public atxControllerAddr;
   

  address[] public memWallets;
  address[] public vaultWallets;

  struct Period {
    uint256 startTime;
    uint256 endTime;
    uint256 bonus;  
  }
  Period[] public periods;

  bool public isInitialized;
  bool public isFinalized;

  function init (
    address _kyc,
    address _token,
    address _hexController,
    address _atxToken,
    address _atxController,
     
    address[] _memWallets,
    address[] _vaultWallets,
    uint256 _ethRate,
    uint256 _atxRate,
    uint256 _maxHEXCap,
    uint256 _minHEXCap ) public onlyOwner {

      require(isInitialized == false);

      kyc = KYC(_kyc);
      hexToken = HEX(_token);
      hexControllerAddr = _hexController;
      atxToken = ERC20Basic(_atxToken);
      atxControllerAddr = _atxController;

      memWallets = _memWallets;
      vaultWallets = _vaultWallets;

       

      ethRate = _ethRate;
      atxRate = _atxRate;

      maxHEXCap = _maxHEXCap;
      minHEXCap = _minHEXCap;

      isInitialized = true;
    }

    function () public payable {
      ethBuy();
    }

    function ethBuy() internal {
       
      require(msg.value >= 50e18);  

      require(isInitialized);
      require(!isFinalized);

      require(msg.sender != 0x0 && msg.value != 0x0);
      require(kyc.registeredAddress(msg.sender));
      require(maxReached() == false);
      require(onSale());

      uint256 fundingAmt = msg.value;
      uint256 bonus = getPeriodBonus();
      uint256 currTotalSupply = hexToken.totalSupply();
      uint256 fundableHEXRoom = sub(maxHEXCap, currTotalSupply);
      uint256 reqedHex = eth2HexWithBonus(fundingAmt, bonus);
      uint256 toFund;
      uint256 reFund;

      if(reqedHex > fundableHEXRoom) {
        reqedHex = fundableHEXRoom;

        toFund = hex2EthWithBonus(reqedHex, bonus);  
        reFund = sub(fundingAmt, toFund);

         
         
         

      } else {
        toFund = fundingAmt;
        reFund = 0;
      }

      require(fundingAmt >= toFund);
      require(toFund > 0);

       
      if(ethInvestorFunds[msg.sender] == 0x0) {
        ethInvestors.push(msg.sender);
      }
      ethInvestorFunds[msg.sender] = add(ethInvestorFunds[msg.sender], toFund);

       

      hexToken.generateTokens(msg.sender, reqedHex);

      if(reFund > 0) {
        msg.sender.transfer(reFund);
      }

       

      emit SaleToken(msg.sender, msg.sender, 0, toFund, reqedHex);
    }

     
     
     
     
     
    function atxBuy(address _from, uint256 _amount) public returns(bool) {
       
      require(_amount >= 250000e18);  

      require(isInitialized);
      require(!isFinalized);

      require(_from != 0x0 && _amount != 0x0);
      require(kyc.registeredAddress(_from));
      require(maxReached() == false);
      require(onSale());

       
      require(msg.sender == atxControllerAddr);

       
      uint256 currAtxBal = atxToken.balanceOf( address(this) );
      require(currAtxBal + _amount >= currAtxBal);  

      uint256 fundingAmt = _amount;
      uint256 bonus = getPeriodBonus();
      uint256 currTotalSupply = hexToken.totalSupply();
      uint256 fundableHEXRoom = sub(maxHEXCap, currTotalSupply);
      uint256 reqedHex = atx2HexWithBonus(fundingAmt, bonus);  
      uint256 toFund;
      uint256 reFund;

      if(reqedHex > fundableHEXRoom) {
        reqedHex = fundableHEXRoom;

        toFund = hex2AtxWithBonus(reqedHex, bonus);  
        reFund = sub(fundingAmt, toFund);

         
         
         

      } else {
        toFund = fundingAmt;
        reFund = 0;
      }

      require(fundingAmt >= toFund);
      require(toFund > 0);


       
      if(atxInvestorFunds[_from] == 0x0) {
        atxInvestors.push(_from);
      }
      atxInvestorFunds[_from] = add(atxInvestorFunds[_from], toFund);

       

      hexToken.generateTokens(_from, reqedHex);

       
       
       
       
       
       
      if(reFund > 0) {
         
        if(atxChanges[_from] == 0x0) {
          atxChangeAddrs.push(_from);
        }
        atxChanges[_from] = add(atxChanges[_from], reFund);
      }

       
       
       
       
       
         
       

      emit SaleToken(msg.sender, _from, 1, toFund, reqedHex);

      return true;
    }

    function finish() public onlyOwner {
      require(!isFinalized);

      returnATXChanges();

      if(minReached()) {

         
        require(vaultWallets.length == 31);
        uint eachATX = div(atxToken.balanceOf(address(this)), vaultWallets.length);
        for(uint idx = 0; idx < vaultWallets.length; idx++) {
           
          atxToken.transfer(vaultWallets[idx], eachATX);
        }
         
        if(atxToken.balanceOf(address(this)) > 0) {
          atxToken.transfer(vaultWallets[vaultWallets.length - 1], atxToken.balanceOf(address(this)));
        }
         
         
          vaultWallets[vaultWallets.length - 1].transfer( address(this).balance );
         

        require(memWallets.length == 6);
        hexToken.generateTokens(memWallets[0], 14e26);  
        hexToken.generateTokens(memWallets[1], 84e25);  
        hexToken.generateTokens(memWallets[2], 84e25);  
        hexToken.generateTokens(memWallets[3], 80e25);  
        hexToken.generateTokens(memWallets[4], 92e25);  
        hexToken.generateTokens(memWallets[5], 80e25);  

         

      } else {
         
      }

      hexToken.finishGenerating();
      hexToken.changeController(hexControllerAddr);

      isFinalized = true;

      emit SaleFinished();
    }

    function maxReached() public view returns (bool) {
      return (hexToken.totalSupply() >= maxHEXCap);
    }

    function minReached() public view returns (bool) {
      return (hexToken.totalSupply() >= minHEXCap);
    }

    function addPeriod(uint256 _start, uint256 _end) public onlyOwner {
      require(now < _start && _start < _end);
      if (periods.length != 0) {
         
        require(periods[periods.length - 1].endTime < _start);
      }
      Period memory newPeriod;
      newPeriod.startTime = _start;
      newPeriod.endTime = _end;
      newPeriod.bonus = 0;
      if(periods.length == 0) {
        newPeriod.bonus = 50;  
      }
      else if(periods.length == 1) {
        newPeriod.bonus = 30;  
      }
      else if(periods.length == 2) {
        newPeriod.bonus = 20;  
      }
      else if (periods.length == 3) {
        newPeriod.bonus = 15;  
      }
      else if (periods.length == 4) {
        newPeriod.bonus = 10;  
      }
      else if (periods.length == 5) {
        newPeriod.bonus = 5;  
      }

      periods.push(newPeriod);
    }

    function getPeriodBonus() public view returns (uint256) {
      bool nowOnSale;
      uint256 currentPeriod;

      for (uint i = 0; i < periods.length; i++) {
        if (periods[i].startTime <= now && now <= periods[i].endTime) {
          nowOnSale = true;
          currentPeriod = i;
          break;
        }
      }

      require(nowOnSale);
      return periods[currentPeriod].bonus;
    }

    function eth2HexWithBonus(uint256 _eth, uint256 bonus) public view returns(uint256) {
      uint basic = mul(_eth, ethRate);
      return div(mul(basic, add(bonus, 100)), 100);
       
    }

    function hex2EthWithBonus(uint256 _hex, uint256 bonus) public view returns(uint256)  {
      return div(mul(_hex, 100), mul(ethRate, add(100, bonus)));
       
    }

    function atx2HexWithBonus(uint256 _atx, uint256 bonus) public view returns(uint256)  {
      uint basic = mul(_atx, atxRate);
      return div(mul(basic, add(bonus, 100)), 100);
       
    }

    function hex2AtxWithBonus(uint256 _hex, uint256 bonus) public view returns(uint256)  {
      return div(mul(_hex, 100), mul(atxRate, add(100, bonus)));
       
    }

    function onSale() public view returns (bool) {
      bool nowOnSale;

       
      for (uint i = 1; i < periods.length; i++) {
        if (periods[i].startTime <= now && now <= periods[i].endTime) {
          nowOnSale = true;
          break;
        }
      }

      return nowOnSale;
    }

    function atxChangeAddrCount() public view returns(uint256) {
      return atxChangeAddrs.length;
    }

    function returnATXChanges() public onlyOwner {
       

      for(uint256 i=0; i<atxChangeAddrs.length; i++) {
        if(atxChanges[atxChangeAddrs[i]] > 0) {
            if( atxToken.transfer(atxChangeAddrs[i], atxChanges[atxChangeAddrs[i]]) ) {
              atxChanges[atxChangeAddrs[i]] = 0x0;
            }
        }
      }
    }

     
     
    function claimTokens(address _claimToken) public onlyOwner {

      if (hexToken.controller() == address(this)) {
           hexToken.claimTokens(_claimToken);
      }

      if (_claimToken == 0x0) {
          owner.transfer(address(this).balance);
          return;
      }

      ERC20Basic claimToken = ERC20Basic(_claimToken);
      uint256 balance = claimToken.balanceOf( address(this) );
      claimToken.transfer(owner, balance);

      emit ClaimedTokens(_claimToken, owner, balance);
    }

     
     

    event SaleToken(address indexed _sender, address indexed _investor, uint256 indexed _fundType, uint256 _toFund, uint256 _hexTokens);
    event ClaimedTokens(address indexed _claimToken, address indexed owner, uint256 balance);
    event SaleFinished();
  }