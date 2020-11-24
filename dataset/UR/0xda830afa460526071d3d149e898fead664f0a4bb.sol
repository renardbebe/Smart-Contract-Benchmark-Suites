 

 
 
 
 

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function percent(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c / 100;
  }
}


 

  
  

 
 
 
 
 
 
 


 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
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
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               Transfer(_from, _to, _amount);     
               return;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

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
        Approval(msg.sender, _spender, _amount);
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

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
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
        Transfer(0, _owner, _amount);
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
        Transfer(_owner, 0, _amount);
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
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
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



contract EatMeCoin is MiniMeToken { 

   
  uint256 public checkpointBlock;

   
  address public mayGenerateAddr;

   
  bool tokenGenerationEnabled = true;  


  modifier mayGenerate() {
    require ( (msg.sender == mayGenerateAddr) &&
              (tokenGenerationEnabled == true) );  
    _;
  }

   
  function EatMeCoin(address _tokenFactory) 
    MiniMeToken(
      _tokenFactory,
      0x0,
      0,
      "EatMeCoin",
      18,  
      "EAT",
       
      false){
    
    controller = msg.sender;
    mayGenerateAddr = controller;
  }

  function setGenerateAddr(address _addr) onlyController{
     
    require( _addr != 0x0 );
    mayGenerateAddr = _addr;
  }


   
   
  function () payable {
    revert();
  }

  
   
   
  function generate_token_for(address _addrTo, uint256 _amount) mayGenerate returns (bool) {
    
     
   
    uint256 curTotalSupply = totalSupply();
    require(curTotalSupply + _amount >= curTotalSupply);  
    uint256 previousBalanceTo = balanceOf(_addrTo);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_addrTo], previousBalanceTo + _amount);
    Transfer(0, _addrTo, _amount);
    return true;
  }

   
  function generateTokens(address _owner, uint256 _amount
    ) onlyController returns (bool) {
    revert();
    generate_token_for(_owner, _amount);    
  }


   
  function finalize() mayGenerate {
    tokenGenerationEnabled = false;
    transfersEnabled = true;
    checkpointBlock = block.number;
  }  
}


contract eat_token_interface{
  uint8 public decimals;
  function generate_token_for(address _addr,uint256 _amount) returns (bool);
  function finalize();
}

 
contract TokenCampaign is Controlled {
  using SafeMath for uint256;

   
  eat_token_interface public token;

  uint8 public constant decimals = 18;

  uint256 public constant scale = (uint256(10) ** decimals);

  uint256 public constant hardcap = 100000000 * scale;

   
   
   

   
   
   

   
  uint256 public constant PRCT100_D_TEAM = 63;  
  uint256 public constant PRCT100_R_TEAM = 250;  
  uint256 public constant PRCT100_R2 = 150;   

   
  uint256 public constant FIXEDREWARD_MM = 100000 * scale;  

   
   
  uint256 public constant PRCT100_ETH_OP = 4000;  

   
  uint256 public constant preCrowdMinContribution = (20 ether);

   
  uint256 public constant minContribution = (1 ether) / 100;

   
  uint256 public constant preCrowd_tokens_scaled = 7142857142857140000000;  
  uint256 public constant stage_1_tokens_scaled =  6250000000000000000000;  
  uint256 public constant stage_2_tokens_scaled =  5555555555555560000000;  
  uint256 public constant stage_3_tokens_scaled =  5000000000000000000000;  

   
  uint256 public constant PreCrowdAllocation =  20000000 * scale ;  
  uint256 public constant Stage1Allocation =    15000000 * scale ;  
  uint256 public constant Stage2Allocation =    15000000 * scale ;  
  uint256 public constant Stage3Allocation =    20000000 * scale ;  

   
  uint256 public tokensRemainingPreCrowd = PreCrowdAllocation;
  uint256 public tokensRemainingStage1 = Stage1Allocation;
  uint256 public tokensRemainingStage2 = Stage2Allocation;
  uint256 public tokensRemainingStage3 = Stage3Allocation;

   
   
   
  uint256 public maxPreCrowdAllocationPerInvestor =  20000000 * scale ;  
  uint256 public maxStage1AllocationPerInvestor =    15000000 * scale ;  
  uint256 public maxStage2AllocationPerInvestor =    15000000 * scale ;  
  uint256 public maxStage3AllocationPerInvestor =    20000000 * scale ;  

   
  uint256 public tokensGenerated = 0;

  address[] public joinedCrowdsale;

   
  uint256 public amountRaised = 0; 

   
  uint256 public amountRefunded = 0;


   
   
   
   
   

   
  address public dteamVaultAddr1;
  address public dteamVaultAddr2;
  address public dteamVaultAddr3;
  address public dteamVaultAddr4;

   
  address public rteamVaultAddr;

   
  address public r2VaultAddr;

   
  address public mmVaultAddr;
  
   
  address public reserveVaultAddr;

   
  address public trusteeVaultAddr;
  
   
  address public opVaultAddr;

   
  address public tokenAddr;
  
   
   
   
   
   
   
  uint8 public campaignState = 3; 
  bool public paused = false;

   
   
  uint256 public tCampaignStart = 64060588800;

  uint256 public t_1st_StageEnd = 5 * (1 days);  
   
   

  uint256 public t_2nd_StageEnd = 2 * (1 days);  
   
   

  uint256 public tCampaignEnd = 35 * (1 days);  
   
   

  uint256 public tFinalized = 64060588800;

   
  struct ParticipantListData {

    bool participatedFlag;

    uint256 contributedAmountPreAllocated;
    uint256 contributedAmountPreCrowd;
    uint256 contributedAmountStage1;
    uint256 contributedAmountStage2;
    uint256 contributedAmountStage3;

    uint256 preallocatedTokens;
    uint256 allocatedTokens;

    uint256 spentAmount;
  }

   
  mapping (address => ParticipantListData) public participantList;

  uint256 public investorsProcessed = 0;
  uint256 public investorsBatchSize = 100;

  bool public isWhiteListed = true;

  struct WhiteListData {
    bool status;
    uint256 maxCap;
  }

   
  mapping (address => WhiteListData) public participantWhitelist;


   
   
   
 
  event CampaignOpen(uint256 timenow);
  event CampaignClosed(uint256 timenow);
  event CampaignPaused(uint256 timenow);
  event CampaignResumed(uint256 timenow);

  event PreAllocated(address indexed backer, uint256 raised);
  event RaisedPreCrowd(address indexed backer, uint256 raised);
  event RaisedStage1(address indexed backer, uint256 raised);
  event RaisedStage2(address indexed backer, uint256 raised);
  event RaisedStage3(address indexed backer, uint256 raised);
  event Airdropped(address indexed backer, uint256 tokensairdropped);

  event Finalized(uint256 timenow);

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);

   
  event Whitelisted(address addr, bool status);

   
  event Refund(address investor, uint256 weiAmount);

   
   
   
   
   
  function TokenCampaign(
    address _tokenAddress,
    address _dteamAddress1,
    address _dteamAddress2,
    address _dteamAddress3,
    address _dteamAddress4,
    address _rteamAddress,
    address _r2Address,
    address _mmAddress,
    address _trusteeAddress,
    address _opAddress,
    address _reserveAddress)
  {

    controller = msg.sender;
    
     
    tokenAddr = _tokenAddress;
    dteamVaultAddr1 = _dteamAddress1;
    dteamVaultAddr2 = _dteamAddress2;
    dteamVaultAddr3 = _dteamAddress3;
    dteamVaultAddr4 = _dteamAddress4;
    rteamVaultAddr = _rteamAddress;
    r2VaultAddr = _r2Address;
    mmVaultAddr = _mmAddress;
    trusteeVaultAddr = _trusteeAddress; 
    opVaultAddr = _opAddress;
    reserveVaultAddr = _reserveAddress;

     
    token = eat_token_interface(tokenAddr);
   
  }


   
   
   

   
   
   

   
   
   
   
  function startSale() public onlyController {
    require( campaignState > 2 );

    campaignState = 2;

    uint256 tNow = now;
     
    tCampaignStart = tNow;
    t_1st_StageEnd += tNow;
    t_2nd_StageEnd += tNow;
    tCampaignEnd += tNow;

    CampaignOpen(now);
  }


   
   
   
  function pauseSale() public onlyController {
    require( campaignState  == 2 );
    paused = true;
    CampaignPaused(now);
  }


   
  function resumeSale() public onlyController {
    require( campaignState  == 2 );
    paused = false;
    CampaignResumed(now);
  }



   
   
   
   
   
  function closeSale() public onlyController {
    require( campaignState  == 2 );
    campaignState = 1;

    CampaignClosed(now);
  }   


  function setParticipantWhitelist(address addr, bool status, uint256 maxCap) public onlyController {
    participantWhitelist[addr] = WhiteListData({status:status, maxCap:maxCap});
    Whitelisted(addr, status);
  }

  function setMultipleParticipantWhitelist(address[] addrs, bool[] statuses, uint[] maxCaps) public onlyController {
    for (uint256 iterator = 0; iterator < addrs.length; iterator++) {
      setParticipantWhitelist(addrs[iterator], statuses[iterator], maxCaps[iterator]);
    }
  }

  function investorCount() public constant returns (uint256) {
    return joinedCrowdsale.length;
  }

  function contractBalance() public constant returns (uint256) {
    return this.balance;
  }

   
  function refund() public {
    require (campaignState == 0);

    uint256 weiValue = participantList[msg.sender].contributedAmountPreCrowd;
    weiValue = weiValue.add(participantList[msg.sender].contributedAmountStage1);
    weiValue = weiValue.add(participantList[msg.sender].contributedAmountStage2);
    weiValue = weiValue.add(participantList[msg.sender].contributedAmountStage3);
    weiValue = weiValue.sub(participantList[msg.sender].spentAmount);

    if (weiValue <= 0) revert();

    participantList[msg.sender].contributedAmountPreCrowd = 0;
    participantList[msg.sender].contributedAmountStage1 = 0;
    participantList[msg.sender].contributedAmountStage2 = 0;
    participantList[msg.sender].contributedAmountStage3 = 0;

    amountRefunded = amountRefunded.add(weiValue);

     
    if (!msg.sender.send(weiValue)) revert();

     
    Refund(msg.sender, weiValue);

  }

   
   
  function allocateInvestors() public onlyController {     
      
     
     

    require ( (campaignState == 1) || ((campaignState != 0) && (now > tCampaignEnd + (2880 minutes))));

    uint256 nTokens = 0;
    uint256 rate = 0;
    uint256 contributedAmount = 0; 

    uint256 investorsProcessedEnd = investorsProcessed + investorsBatchSize;

    if (investorsProcessedEnd > joinedCrowdsale.length) {
      investorsProcessedEnd = joinedCrowdsale.length;
    }

    for (uint256 i = investorsProcessed; i < investorsProcessedEnd; i++) {

        investorsProcessed++;

        address investorAddress = joinedCrowdsale[i];

         
        contributedAmount = participantList[investorAddress].contributedAmountPreCrowd;

        if (isWhiteListed) {

             
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

             
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

             
            rate = preCrowd_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

             
            if (nTokens > maxPreCrowdAllocationPerInvestor) {
              nTokens = maxPreCrowdAllocationPerInvestor;
            }

             
            if (tokensRemainingPreCrowd.sub(nTokens) < 0) {
                nTokens = tokensRemainingPreCrowd;
            }

             
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

             
            tokensRemainingPreCrowd = tokensRemainingPreCrowd.sub(nTokens);

             
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

         
        contributedAmount = participantList[investorAddress].contributedAmountStage1;

        if (isWhiteListed) {

             
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

             
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

             
            rate = stage_1_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

             
            if (nTokens > maxStage1AllocationPerInvestor) {
              nTokens = maxStage1AllocationPerInvestor;
            }

             
            if (tokensRemainingStage1.sub(nTokens) < 0) {
                nTokens = tokensRemainingStage1;
            }

             
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

             
            tokensRemainingStage1 = tokensRemainingStage1.sub(nTokens);

             
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

         
        contributedAmount = participantList[investorAddress].contributedAmountStage2;

        if (isWhiteListed) {

             
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

             
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

             
            rate = stage_2_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

             
            if (nTokens > maxStage2AllocationPerInvestor) {
              nTokens = maxStage2AllocationPerInvestor;
            }

             
            if (tokensRemainingStage2.sub(nTokens) < 0) {
                nTokens = tokensRemainingStage2;
            }

             
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

             
            tokensRemainingStage2 = tokensRemainingStage2.sub(nTokens);

             
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

         
        contributedAmount = participantList[investorAddress].contributedAmountStage3;

        if (isWhiteListed) {

             
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

             
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

             
            rate = stage_3_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

             
            if (nTokens > maxStage3AllocationPerInvestor) {
              nTokens = maxStage3AllocationPerInvestor;
            }

             
            if (tokensRemainingStage3.sub(nTokens) < 0) {
                nTokens = tokensRemainingStage3;
            }

             
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

             
            tokensRemainingStage3 = tokensRemainingStage3.sub(nTokens);

             
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

        do_grant_tokens(investorAddress, participantList[investorAddress].allocatedTokens);

    }

  }

   
   
  function finalizeCampaign() public onlyController {     
      
     
     

    require ( (campaignState == 1) || ((campaignState != 0) && (now > tCampaignEnd + (2880 minutes))));

    campaignState = 0;

     
    uint256 drewardTokens = (tokensGenerated.mul(PRCT100_D_TEAM)).div(10000);

     
    uint256 rrewardTokens = (tokensGenerated.mul(PRCT100_R_TEAM)).div(10000);

     
    uint256 r2rewardTokens = (tokensGenerated.mul(PRCT100_R2)).div(10000);

     
    uint256 mmrewardTokens = FIXEDREWARD_MM;

    do_grant_tokens(dteamVaultAddr1, drewardTokens);
    do_grant_tokens(dteamVaultAddr2, drewardTokens);
    do_grant_tokens(dteamVaultAddr3, drewardTokens);
    do_grant_tokens(dteamVaultAddr4, drewardTokens);     
    do_grant_tokens(rteamVaultAddr, rrewardTokens);
    do_grant_tokens(r2VaultAddr, r2rewardTokens);
    do_grant_tokens(mmVaultAddr, mmrewardTokens);

     
     
    uint256 reserveTokens = hardcap.sub(tokensGenerated);
    do_grant_tokens(reserveVaultAddr, reserveTokens);

     
    token.finalize();

    tFinalized = now;
    
     
    Finalized(tFinalized);
  }


   
  function retrieveFunds() public onlyController {     

      require (campaignState == 0);
      
       
       
       
       

       

      trusteeVaultAddr.transfer(this.balance);

  }

      
  function emergencyFinalize() public onlyController {     

    campaignState = 0;

     
    token.finalize();

  }


   
   
   
   
  function do_grant_tokens(address _to, uint256 _nTokens) internal returns (bool){
    
    require( token.generate_token_for(_to, _nTokens) );
    
    tokensGenerated = tokensGenerated.add(_nTokens);
    
    return true;
  }


   
   
   
  function process_contribution(address _toAddr) internal {

    require ((campaignState == 2)    
         && (now <= tCampaignEnd)    
         && (paused == false));      
    
     
     
    require ( msg.value >= minContribution );

    amountRaised = amountRaised.add(msg.value);

     
    if (!participantList[_toAddr].participatedFlag) {

        
       participantList[_toAddr].participatedFlag = true;
       joinedCrowdsale.push(_toAddr);
    }

    if ( msg.value >= preCrowdMinContribution ) {

      participantList[_toAddr].contributedAmountPreCrowd = participantList[_toAddr].contributedAmountPreCrowd.add(msg.value);
      
       
      RaisedPreCrowd(_toAddr, msg.value);

    } else {

      if (now <= t_1st_StageEnd) {

        participantList[_toAddr].contributedAmountStage1 = participantList[_toAddr].contributedAmountStage1.add(msg.value);

         
        RaisedStage1(_toAddr, msg.value);

      } else if (now <= t_2nd_StageEnd) {

        participantList[_toAddr].contributedAmountStage2 = participantList[_toAddr].contributedAmountStage2.add(msg.value);

         
        RaisedStage2(_toAddr, msg.value);

      } else {

        participantList[_toAddr].contributedAmountStage3 = participantList[_toAddr].contributedAmountStage3.add(msg.value);
        
         
        RaisedStage3(_toAddr, msg.value);

      }

    }

     
    uint256 opEth = (PRCT100_ETH_OP.mul(msg.value)).div(10000);

     
    opVaultAddr.transfer(opEth);

     
    reserveVaultAddr.transfer(opEth);

  }

   
  function preallocate(address _toAddr, uint fullTokens, uint weiPaid) public onlyController {

    require (campaignState != 0);

    uint tokenAmount = fullTokens * scale;
    uint weiAmount = weiPaid ;  

    if (!participantList[_toAddr].participatedFlag) {

        
       participantList[_toAddr].participatedFlag = true;
       joinedCrowdsale.push(_toAddr);

    }

    participantList[_toAddr].contributedAmountPreAllocated = participantList[_toAddr].contributedAmountPreAllocated.add(weiAmount);
    participantList[_toAddr].preallocatedTokens = participantList[_toAddr].preallocatedTokens.add(tokenAmount);

    amountRaised = amountRaised.add(weiAmount);

     
    require( do_grant_tokens(_toAddr, tokenAmount) );

     
    PreAllocated(_toAddr, weiAmount);

  }

  function airdrop(address _toAddr, uint fullTokens) public onlyController {

    require (campaignState != 0);

    uint tokenAmount = fullTokens * scale;

    if (!participantList[_toAddr].participatedFlag) {

        
       participantList[_toAddr].participatedFlag = true;
       joinedCrowdsale.push(_toAddr);

    }

    participantList[_toAddr].preallocatedTokens = participantList[_toAddr].allocatedTokens.add(tokenAmount);

     
    require( do_grant_tokens(_toAddr, tokenAmount) );

     
    Airdropped(_toAddr, fullTokens);

  }

  function multiAirdrop(address[] addrs, uint[] fullTokens) public onlyController {

    require (campaignState != 0);

    for (uint256 iterator = 0; iterator < addrs.length; iterator++) {
      airdrop(addrs[iterator], fullTokens[iterator]);
    }
  }

   
  function setInvestorsBatchSize(uint256 _batchsize) public onlyController {
      investorsBatchSize = _batchsize;
  }

   
  function setMaxPreCrowdAllocationPerInvestor(uint256 _cap) public onlyController {
      maxPreCrowdAllocationPerInvestor = _cap;
  }

   
  function setMaxStage1AllocationPerInvestor(uint256 _cap) public onlyController {
      maxStage1AllocationPerInvestor = _cap;
  }

   
  function setMaxStage2AllocationPerInvestor(uint256 _cap) public onlyController {
      maxStage2AllocationPerInvestor = _cap;
  }

   
  function setMaxStage3AllocationPerInvestor(uint256 _cap) public onlyController {
      maxStage3AllocationPerInvestor = _cap;
  }

  function setdteamVaultAddr1(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr1 = _newAddr;
  }

  function setdteamVaultAddr2(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr2 = _newAddr;
  }

  function setdteamVaultAddr3(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr3 = _newAddr;
  }

  function setdteamVaultAddr4(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr4 = _newAddr;
  }

  function setrteamVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    rteamVaultAddr = _newAddr;
  }

  function setr2VaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    r2VaultAddr = _newAddr;
  }

  function setmmVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    mmVaultAddr = _newAddr;
  }

  function settrusteeVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    trusteeVaultAddr = _newAddr;
  }

  function setopVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    opVaultAddr = _newAddr;
  }

  function toggleWhitelist(bool _isWhitelisted) public onlyController {
    isWhiteListed = _isWhitelisted;
  }

   
   
   
  function proxy_contribution(address _toAddr) public payable {
    require ( _toAddr != 0x0 );

    process_contribution(_toAddr);
  }


   
  function () payable {
      process_contribution(msg.sender); 
  }

   
   
  function claimTokens(address _tokenAddr) public onlyController {

      ERC20Basic some_token = ERC20Basic(_tokenAddr);
      uint256 balance = some_token.balanceOf(this);
      some_token.transfer(controller, balance);
      ClaimedTokens(_tokenAddr, controller, balance);
  }
}