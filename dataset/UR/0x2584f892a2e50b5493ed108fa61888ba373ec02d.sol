 

pragma solidity ^0.4.11;

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
}

 
 
contract Owned {

     
     
    modifier onlyOwner() {
        if(msg.sender != owner) throw;
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Controlled {
     
     
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract StandardToken is ERC20Token ,Controlled{

    bool public showValue=true;

     
    bool public transfersEnabled;

    function transfer(address _to, uint256 _value) returns (bool success) {

        if(!transfersEnabled) throw;

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

        if(!transfersEnabled) throw;
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        if(!showValue)
        return 0;
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(!transfersEnabled) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        if(!transfersEnabled) throw;
        return allowed[_owner][_spender];
    }

     
     
    function enableTransfers(bool _transfersEnabled) onlyController {
        transfersEnabled = _transfersEnabled;
    }
    function enableShowValue(bool _showValue) onlyController {
        showValue = _showValue;
    }

    function generateTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply;
        if (curTotalSupply + _amount < curTotalSupply) throw;  
        totalSupply=curTotalSupply + _amount;

        balances[_owner]+=_amount;

        Transfer(0, _owner, _amount);
        return true;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MiniMeTokenSimple is StandardToken {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.1';  


     
     
    address public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
    address public tokenFactory;

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeTokenSimple(
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
    ) {
        tokenFactory = _tokenFactory;
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }
     
     
     

     
     
     
     
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

}


contract PFCContribution is Owned {

    using SafeMath for uint256;
    MiniMeTokenSimple public PFC;
    uint256 public ratio=25000;

    uint256 public constant MIN_FUND = (0.001 ether);

    uint256 public startTime=0 ;
    uint256 public endTime =0;
    uint256 public finalizedBlock=0;
    uint256 public finalizedTime=0;

    bool public isFinalize = false;

    uint256 public totalContributedETH = 0;
    uint256 public totalTokenSaled=0;

    uint256 public MaxEth=15000 ether;


    address public pfcController;
    address public destEthFoundation;

    bool public paused;

    modifier initialized() {
        require(address(PFC) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(time() >= startTime &&
        time() <= endTime &&
        finalizedBlock == 0 &&
        address(PFC) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function PFCCContribution() {
        paused = false;
    }


     
     
     
     
     
     
     
     
    function initialize(
    address _pfc,
    address _pfcController,
    uint256 _startTime,
    uint256 _endTime,
    address _destEthFoundation,
    uint256 _maxEth
    ) public onlyOwner {
         
        require(address(PFC) == 0x0);

        PFC = MiniMeTokenSimple(_pfc);
        require(PFC.totalSupply() == 0);
        require(PFC.controller() == address(this));
        require(PFC.decimals() == 18);   

        startTime = _startTime;
        endTime = _endTime;

        assert(startTime < endTime);

        require(_pfcController != 0x0);
        pfcController = _pfcController;

        require(_destEthFoundation != 0x0);
        destEthFoundation = _destEthFoundation;

        require(_maxEth >1 ether);
        MaxEth=_maxEth;
    }

     
     
    function () public payable notPaused {

        if(totalContributedETH>=MaxEth) throw;
        proxyPayment(msg.sender);
    }


     
     
     

     
     
     
     
    function proxyPayment(address _account) public payable initialized contributionOpen returns (bool) {
        require(_account != 0x0);

        require( msg.value >= MIN_FUND );

        uint256 tokenSaling;
        uint256 rValue;
        uint256 t_totalContributedEth=totalContributedETH+msg.value;
        uint256 reFund=0;
        if(t_totalContributedEth>MaxEth) {
            reFund=t_totalContributedEth-MaxEth;
        }
        rValue=msg.value-reFund;
        tokenSaling=rValue.mul(ratio);
        if(reFund>0)
        msg.sender.transfer(reFund);
        assert(PFC.generateTokens(_account,tokenSaling));
        destEthFoundation.transfer(rValue);

        totalContributedETH +=rValue;
        totalTokenSaled+=tokenSaling;

        NewSale(msg.sender, rValue,tokenSaling);
    }

    function setMaxEth(uint256 _maxEth) onlyOwner initialized{
        MaxEth=_maxEth;
    }

    function setRatio(uint256 _ratio) onlyOwner initialized{
        ratio=_ratio;
    }

    function issueTokenToAddress(address _account, uint256 _amount) onlyOwner initialized {


        assert(PFC.generateTokens(_account, _amount));

        totalTokenSaled +=_amount;

        NewIssue(_account, _amount);

    }

    function finalize() public onlyOwner initialized {
        require(time() >= startTime);

        require(finalizedBlock == 0);

        finalizedBlock = getBlockNumber();
        finalizedTime = now;

        PFC.changeController(pfcController);
        isFinalize=true;
        Finalized();
    }

    function time() constant returns (uint) {
        return block.timestamp;
    }

     
     
     

     
    function tokensIssued() public constant returns (uint256) {
        return PFC.totalSupply();
    }

     
     
     

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

     
     
     

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (PFC.controller() == address(this)) {
            PFC.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

     
    function pauseContribution() onlyOwner {
        paused = true;
    }

     
    function resumeContribution() onlyOwner {
        paused = false;
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event NewSale(address _account, uint256 _amount,uint256 _tokenAmount);
    event NewIssue(address indexed _th, uint256 _amount);
    event Finalized();
}