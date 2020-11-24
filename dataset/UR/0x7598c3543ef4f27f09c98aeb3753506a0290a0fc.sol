 

pragma solidity ^0.4.10;

 

 
 
 
 
 

contract tmed {
    
string public name; 
string public symbol; 
uint8 public decimals; 
uint256 public maxRewardUnitsAvailable;
uint256 public startTime;
uint256 public totalSupply;

 
 
bool public frozen;
bool public freezeProhibited;

address public devAddress;  

bool importsComplete;  

mapping (address => uint256) public burnAmountAllowed;

mapping(address => mapping (address => uint256)) allowed;

 
mapping(address => uint256) balances;

mapping (address => uint256) public numRewardsAvailable;

 
bool public TMEXAddressSet;
address public TMEXAddress;

bool devTestBalanceAdded;

event Transfer(address indexed from, address indexed to, uint256 value);
 
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

function tmed() {
name = "tmed";
symbol = "TMED";
decimals = 18;
startTime=1500307354;  
devAddress=0x85196Da9269B24bDf5FfD2624ABB387fcA05382B;  
if (!devTestBalanceAdded)  {
    devTestBalanceAdded=true;
     
     
     
    balances[devAddress]+=1000000000000000000;
    numRewardsAvailable[devAddress]=10;
}
}

 
function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
}

function transfer(address _to, uint256 _value) { 
if (!frozen){
    
    if (balances[msg.sender] < _value) revert();
    if (balances[_to] + _value < balances[_to]) revert();

    if (returnIsParentAddress(_to))     {
        if (msg.sender==returnChildAddressForParent(_to))  {
            if (numRewardsAvailable[msg.sender]>0)    {
                uint256 currDate=block.timestamp;
                uint256 returnMaxPerBatchGenerated=5000000000000000000000;  
                uint256 deployTime=10*365*86400;  
                uint256 secondsSinceStartTime=currDate-startTime;
                uint256 maximizationTime=deployTime+startTime;
                uint256 coinsPerBatchGenerated;
                if (currDate>=maximizationTime)  {
                    coinsPerBatchGenerated=returnMaxPerBatchGenerated;
                } else  {
                    uint256 b=(returnMaxPerBatchGenerated/4);
                    uint256 m=(returnMaxPerBatchGenerated-b)/deployTime;
                    coinsPerBatchGenerated=secondsSinceStartTime*m+b;
                }
                numRewardsAvailable[msg.sender]-=1;
                balances[msg.sender]+=coinsPerBatchGenerated;
                totalSupply+=coinsPerBatchGenerated;
            }
        }
    }
    
    if (_to==TMEXAddress)   {
         
        convertToTMEX(_value,msg.sender);
    }
    
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
}
}

function transferFrom(
        address _from,
        address _to,
        uint256 _amount
) returns (bool success) {
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        return true;
    } else {
        return false;
    }
}
  
 
 
function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
}

 
function setNumRewardsAvailableForAddress(uint256 numRewardsAvailableForAddress,address addressToSetFor)    {
    if (tx.origin==devAddress) {  
       if (!importsComplete)  {
           numRewardsAvailable[addressToSetFor]=numRewardsAvailableForAddress;
       }
    }
}

 
function freezeTransfers() {
    if (tx.origin==devAddress) {  
        if (!freezeProhibited)  {
               frozen=true;
        }
    }
}

 
function prohibitFreeze()   {
    if (tx.origin==devAddress) {  
        freezeProhibited=true;
    }
}

 
function returnIsParentAddress(address possibleParent) returns(bool)  {
    return tme(0xEe22430595aE400a30FFBA37883363Fbf293e24e).parentAddress(possibleParent);
}

 
function returnChildAddressForParent(address parent) returns(address)  {
    return tme(0xEe22430595aE400a30FFBA37883363Fbf293e24e).returnChildAddressForParent(parent);
}

 
function setTMEXAddress(address TMEXAddressToSet)   {
    if (tx.origin==devAddress) {  
        if (!TMEXAddressSet)  {
                TMEXAddressSet=true;
               TMEXAddress=TMEXAddressToSet;
        }
    }
}

 
function convertToTMEX(uint256 amount,address sender) private   {
    totalSupply-=amount;
    burnAmountAllowed[sender]=amount;
    timereumX(TMEXAddress).createAmountFromTmedForAddress(amount,sender);
    burnAmountAllowed[sender]=0;
}

function returnAmountOfTmexAddressCanProduce(address producingAddress) public returns(uint256)   {
    return burnAmountAllowed[producingAddress];
}

}

 
contract tme    {
    function parentAddress(address possibleParent) public returns(bool);
    function returnChildAddressForParent(address parentAddressOfChild) public returns(address);
}

contract timereumX {
    function createAmountFromTmedForAddress(uint256 amount,address sender);
}