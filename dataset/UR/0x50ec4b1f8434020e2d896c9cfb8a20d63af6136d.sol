 

pragma solidity ^0.4.25;
 
 
 

 
 
 
 
 
 
 

 
 
 

 
 

 

 
 

 
 
 
 
 

 
 
 

 
 
 

 
 

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 
contract Snip3D is  Owned {
    using SafeMath for uint;
    uint public _totalSupply;

    mapping(address => uint256)public  balances; 
    mapping(address => uint256)public  bullets; 
    mapping(uint256 => address)public  formation; 
    uint256 public nextFormation; 
    mapping(address => uint256)public lastMove; 
    mapping(uint256 => address) public RefundWaitingLine;
    uint256 public  NextInLine; 
    uint256 public  NextAtLineEnd; 
    uint256 public Refundpot;
    uint256 public blocksBeforeSemiRandomShoot = 10;
    uint256 public blocksBeforeTargetShoot = 40;
    
     
    constructor()
        public
    {
        
        
    }
     
    modifier isAlive()
    {
        require(balances[msg.sender] > 0);
        _;
    }
     
HourglassInterface constant P3Dcontract_ = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
SPASMInterface constant SPASM_ = SPASMInterface(0xfaAe60F2CE6491886C9f7C9356bd92F688cA66a1);
 
function harvestabledivs()
        view
        public
        returns(uint256)
    {
        return ( P3Dcontract_.dividendsOf(address(this)))  ;
    }
function amountofp3d() external view returns(uint256){
    return ( P3Dcontract_.balanceOf(address(this)))  ;
}
     
uint256 public pointMultiplier = 10e18;
struct Account {
  uint balance;
  uint lastDividendPoints;
}
mapping(address=>Account) accounts;
mapping(address => string) public Vanity;
uint public ethtotalSupply;
uint public totalDividendPoints;
uint public unclaimedDividends;

function dividendsOwing(address account) public view returns(uint256) {
  uint256 newDividendPoints = totalDividendPoints.sub(accounts[account].lastDividendPoints);
  return (balances[account] * newDividendPoints) / pointMultiplier;
}
modifier updateAccount(address account) {
  uint256 owing = dividendsOwing(account);
  if(owing > 0) {
    unclaimedDividends = unclaimedDividends.sub(owing);
    
    account.transfer(owing);
  }
  accounts[account].lastDividendPoints = totalDividendPoints;
  _;
}
function () external payable{}
function fetchdivs(address toupdate) public updateAccount(toupdate){}
 
function sendInSoldier(address masternode) public updateAccount(msg.sender)  payable{
    uint256 value = msg.value;
    require(value >= 100 finney); 
    address sender = msg.sender;
     
    balances[sender]++;
     
    _totalSupply++;
     
    bullets[sender]++;
     
    formation[nextFormation] = sender;
    nextFormation++;
     
    lastMove[sender] = block.number;
     
    P3Dcontract_.buy.value(5 wei)(masternode);
     
    if(value > 100 finney){uint256 toRefund = value.sub(100 finney);Refundpot.add(toRefund);}
     
    Refundpot += 5 finney;
     
    SPASM_.disburse.value(1 wei)();

}
function shootSemiRandom() public isAlive() {
    address sender = msg.sender;
    require(block.number > lastMove[sender] + blocksBeforeSemiRandomShoot);
    require(bullets[sender] > 0);
    uint256 semiRNG = (block.number.sub(lastMove[sender])) % 200;
    
    uint256 shot = uint256 (blockhash(block.number.sub(semiRNG))) % nextFormation;
    address killed = formation[shot];
     
    if(sender == killed)
    {
        shot = uint256 (blockhash(block.number.sub(semiRNG).add(1))) % nextFormation;
        killed = formation[shot];
    }
    
     
    balances[killed]--;
     
    _totalSupply--;
     
    bullets[sender]--;
     
    uint256 lastEntry = nextFormation.sub(1);
    formation[shot] = formation[lastEntry];
    nextFormation--;
     
    lastMove[sender] = block.number;
     
    fetchdivs(killed);
     
    RefundWaitingLine[NextAtLineEnd] = killed;
    NextAtLineEnd++;
     
    uint256 amount = 89 finney;
    totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(_totalSupply));
    unclaimedDividends = unclaimedDividends.add(amount);

}
function shootTarget(uint256 target) public isAlive() {
    address sender = msg.sender;
    require(target < nextFormation && target > 0);
    require(block.number > lastMove[sender] + blocksBeforeTargetShoot);
    require(bullets[sender] > 0);
    
    address killed = formation[target];
     
    
    
     
    balances[killed]--;
     
    _totalSupply--;
     
    bullets[sender]--;
     
    uint256 lastEntry = nextFormation.sub(1);
    formation[target] = formation[lastEntry];
    nextFormation--;
     
    lastMove[sender] = block.number;
     
    fetchdivs(killed);
     
    RefundWaitingLine[NextAtLineEnd] = killed;
    NextAtLineEnd++;
     
     
            uint256 dividends =  harvestabledivs();
            require(dividends > 0);
            uint256 base = dividends.div(100);
            P3Dcontract_.withdraw();
            SPASM_.disburse.value(base)(); 
     
    uint256 amount = 89 finney;
    amount = amount.add(dividends.sub(base));
    totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(_totalSupply));
    unclaimedDividends = unclaimedDividends.add(amount);

}

function Payoutnextrefund ()public
    {
         
            uint256 Pot = Refundpot;
            require(Pot > 0.1 ether);
            Refundpot -= 0.1 ether;
            RefundWaitingLine[NextInLine].transfer(0.1 ether);
            NextInLine++;
             
    }

function disburse() public  payable {
    uint256 amount = msg.value;
    uint256 base = amount.div(100);
    uint256 amt2 = amount.sub(base);
  totalDividendPoints = totalDividendPoints.add(amt2.mul(pointMultiplier).div(_totalSupply));
 unclaimedDividends = unclaimedDividends.add(amt2);
 
}
function changevanity(string van) public payable{
    require(msg.value >= 1  finney);
    Vanity[msg.sender] = van;
    Refundpot += msg.value;
}
function P3DDivstocontract() public payable{
    uint256 divs = harvestabledivs();
    require(divs > 0);
 
P3Dcontract_.withdraw();
     
    uint256 base = divs.div(100);
    uint256 amt2 = divs.sub(base);
    SPASM_.disburse.value(base)(); 
   totalDividendPoints = totalDividendPoints.add(amt2.mul(pointMultiplier).div(_totalSupply));
 unclaimedDividends = unclaimedDividends.add(amt2);
}
function die () public onlyOwner {
    selfdestruct(msg.sender);
}

    
}
interface HourglassInterface  {
    function() payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function exit() external;
    function dividendsOf(address _playerAddress) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function stakingRequirement() external view returns(uint256);
}
interface SPASMInterface  {
    function() payable external;
    function disburse() external  payable;
}