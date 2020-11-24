 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 
 


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
contract Owned {
     
     
    modifier onlyOwner { require (msg.sender == owner); _; }

    address public owner;

     
    function Owned() public { owner = msg.sender;}

     
     
     
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
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






 
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}


contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}


 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
    address _parentToken,
    uint _snapshotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
    ) public returns (MiniMeToken)
    {
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


 

 
 
 
 
 
 
 
 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = "1.0.0"; 

     
     
     
    struct Checkpoint {

         
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
    ) public 
    {
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

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) 
        public returns (bool success) 
        {
         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) {
                return false;
            }
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) 
    {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        return doApprove(_spender, _amount);
    }

    function doApprove(address _spender, uint256 _amount) internal returns (bool success) {
        require(transfersEnabled);
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) 
    {
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
        returns (uint) 
    {
         
         
         
         
         
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
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

         
         
         
         
         
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
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
        ) public returns(address) 
    {
        if (_snapshotBlock == 0) {
            _snapshotBlock = block.number;
        }

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

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount) 
        public onlyController returns (bool) 
    {
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
    ) onlyController public returns (bool) 
    {
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

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) 
        constant internal returns (uint) 
    {
        if (checkpoints.length == 0) {
            return 0;
        }

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
            
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

         
        uint min = 0;
        uint max = checkpoints.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  
    {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length-1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
               newCheckPoint.fromBlock = uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
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



 
contract TokenController {
   
   
   
  function proxyPayment(address _owner) public payable returns(bool);

   
   
   
   
   
   
  function onTransfer(address _from, address _to, uint _amount) public returns(bool);

   
   
   
   
   
   
  function onApprove(address _owner, address _spender, uint _amount)
  public
  returns(bool);
}



contract FundRequestTokenGeneration is Pausable, TokenController {
    using SafeMath for uint256;

    MiniMeToken public tokenContract;

    address public tokensaleWallet;

    address public founderWallet;

    uint public rate;

    mapping (address => uint) public deposits;

    mapping (address => Countries) public allowed;

    uint public maxCap;          
    uint256 public totalCollected;          

     
    bool public personalCapActive = true;

    uint256 public personalCap;

     
    enum Countries {NOT_WHITELISTED, CHINA, KOREA, USA, OTHER}
    mapping (uint => bool) public allowedCountries;

     
    event Paid(address indexed _beneficiary, uint256 _weiAmount, uint256 _tokenAmount, bool _personalCapActive);

    function FundRequestTokenGeneration(
    address _tokenAddress,
    address _founderWallet,
    address _tokensaleWallet,
    uint _rate,
    uint _maxCap,
    uint256 _personalCap) public
    {
        tokenContract = MiniMeToken(_tokenAddress);
        tokensaleWallet = _tokensaleWallet;
        founderWallet = _founderWallet;

        rate = _rate;
        maxCap = _maxCap;
        personalCap = _personalCap;

        allowedCountries[uint(Countries.CHINA)] = true;
        allowedCountries[uint(Countries.KOREA)] = true;
        allowedCountries[uint(Countries.USA)] = true;
        allowedCountries[uint(Countries.OTHER)] = true;
    }

    function() public payable whenNotPaused {
        doPayment(msg.sender);
    }

     
     
     

    function proxyPayment(address _owner) public payable whenNotPaused returns (bool) {
        doPayment(_owner);
        return true;
    }

    function doPayment(address beneficiary) whenNotPaused internal {
        require(validPurchase(beneficiary));
        require(maxCapNotReached());
        require(personalCapNotReached(beneficiary));
        uint256 weiAmount = msg.value;
        uint256 updatedWeiRaised = totalCollected.add(weiAmount);
        uint256 tokensInWei = weiAmount.mul(rate);
        totalCollected = updatedWeiRaised;
        deposits[beneficiary] = deposits[beneficiary].add(msg.value);
        distributeTokens(beneficiary, tokensInWei);
        Paid(beneficiary, weiAmount, tokensInWei, personalCapActive);
        forwardFunds();
        return;
    }

    function allocateTokens(address beneficiary, uint256 tokensSold) public onlyOwner {
        distributeTokens(beneficiary, tokensSold);
    }

    function finalizeTokenSale() public onlyOwner {
        pause();
        tokenContract.changeController(owner);
    }

    function distributeTokens(address beneficiary, uint256 tokensSold) internal {
        uint256 totalTokensInWei = tokensSold.mul(100).div(40);
        require(tokenContract.generateTokens(beneficiary, tokensSold));
        require(generateExtraTokens(totalTokensInWei, tokensaleWallet, 60));
    }

    function validPurchase(address beneficiary) internal view returns (bool) {
        require(tokenContract.controller() != 0);
        require(msg.value >= 0.01 ether);

        Countries beneficiaryCountry = allowed[beneficiary];

         
        require(uint(beneficiaryCountry) > uint(Countries.NOT_WHITELISTED));

         
        require(allowedCountries[uint(beneficiaryCountry)] == true);
        return true;
    }

    function generateExtraTokens(uint256 _total, address _owner, uint _pct) internal returns (bool) {
        uint256 tokensInWei = _total.div(100).mul(_pct);
        require(tokenContract.generateTokens(_owner, tokensInWei));
        return true;
    }

    function allow(address beneficiary, Countries _country) public onlyOwner {
        allowed[beneficiary] = _country;
    }

    function allowMultiple(address[] _beneficiaries, Countries _country) public onlyOwner {
        for (uint b = 0; b < _beneficiaries.length; b++) {
            allow(_beneficiaries[b], _country);
        }
    }

    function allowCountry(Countries _country, bool _allowed) public onlyOwner {
        require(uint(_country) > 0);
        allowedCountries[uint(_country)] = _allowed;
    }

    function maxCapNotReached() internal view returns (bool) {
        return totalCollected.add(msg.value) <= maxCap;
    }

    function personalCapNotReached(address _beneficiary) internal view returns (bool) {
        if (personalCapActive) {
            return deposits[_beneficiary].add(msg.value) <= personalCap;
        }
        else {
            return true;
        }
    }

    function setMaxCap(uint _maxCap) public onlyOwner {
        maxCap = _maxCap;
    }

     
    function setTokensaleWallet(address _tokensaleWallet) public onlyOwner {
        tokensaleWallet = _tokensaleWallet;
    }

    function setFounderWallet(address _founderWallet) public onlyOwner {
        founderWallet = _founderWallet;
    }


    function setPersonalCap(uint256 _capInWei) public onlyOwner {
        personalCap = _capInWei;
    }

    function setPersonalCapActive(bool _active) public onlyOwner {
        personalCapActive = _active;
    }

    function forwardFunds() internal {
        founderWallet.transfer(msg.value);
    }

     
    function withdrawToken(address _token, uint256 _amount) public onlyOwner {
        require(MiniMeToken(_token).transfer(owner, _amount));
    }

     
    function withdraw(address _to) public onlyOwner {
        _to.transfer(this.balance);
    }

    function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
        return true;
    }

    function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
        return true;
    }
}