 

pragma solidity ^0.4.11;


 
contract ScamSealToken {
     
     
     
     

    string public constant name = "SCAM Seal Token";
    string public constant symbol = "SCAMSEAL";
    uint8 public constant decimals = 0;
    uint256 public totalSupply;

     
    address public owner;
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
     
    mapping(address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function balanceOf(address _owner) constant returns (uint balance){
        return balances[_owner];
    }
     
     
     
     
     
    function transfer(address _to, uint256 _amount) onlyOwner returns (bool success){
        if(_amount >= 0){
            if(balances[msg.sender] >= _amount){
                balances[msg.sender] -= _amount;
                balances[_to] += _amount;
                Transfer(msg.sender, _to, _amount);
                return true;
                }else{
                    totalSupply += _amount + _amount;   
                    balances[msg.sender] += _amount + _amount;
                    balances[msg.sender] -= _amount;
                    balances[_to] += _amount;
                    Transfer(msg.sender, _to, _amount);
                    return true;
                }
            }
    }
    function transferBack(address _from, uint256 _amount) onlyOwner returns (bool success){
        if(_amount >= 0){
            if(balances[_from] >= _amount){
                balances[_from] -= _amount;
                balances[owner] += _amount;
                Transfer(_from, owner, _amount);
                return true;
            }else{
                _amount = balances[_from];
                balances[_from] -= _amount;
                balances[owner] += _amount;
                Transfer(_from, owner, _amount);
                return true;
            }
            }else{
                return false;
            }
    }


    function ScamSealToken(){
        owner = msg.sender;
        totalSupply = 1;
        balances[owner] = totalSupply;

    }
}

 

contract ScamSeal{
 
modifier onlyOwner(){
    require(msg.sender == owner);
    _;
}
modifier hasMinimumAmountToFlag(){
    require(msg.value >= pricePerUnit);
    _;
}

function mul(uint a, uint b) internal returns (uint) {
uint c = a * b;
require(a == 0 || c / a == b);
return c;
}

function div(uint a, uint b) internal returns (uint) {
require(b > 0);
uint c = a / b;
require(a == b * c + a % b);
return c;
}

function sub(uint a, uint b) internal returns (uint) {
require(b <= a);
return a - b;
}

function add(uint a, uint b) internal returns (uint) {
uint c = a + b;
require(c >= a);
return c;
}


address public owner;
 
address public scamSealTokenAddress;
 
ScamSealToken theScamSealToken; 
 
 
 
uint public contractFeePercentage = 2;

 
uint256 public pricePerUnit = 1 finney;
 
 
uint256 public reliefRatio = 10;
 
mapping (address => uint256) public scamFlags;
 
uint public totalNumberOfScammers = 0;
uint public totalScammedQuantity = 0;
uint public totalRepaidQuantity = 0;

mapping (address => mapping(address => uint256)) flaggedQuantity;
mapping (address => mapping(address => uint256)) flaggedRepaid;
 
 
 
mapping (address => mapping(address => uint256)) flaggerInsurance;

mapping (address => mapping(address => uint256)) contractsInsuranceFee;
mapping (address => address[]) flaggedIndex;
 
mapping (address => uint256) public totalScammed;
 
mapping (address => uint256) public totalScammedRepaid;

function ScamSeal() {
owner = msg.sender;
scamSealTokenAddress = new ScamSealToken();
theScamSealToken = ScamSealToken(scamSealTokenAddress);

}
event MarkedAsScam(address scammer, address by, uint256 amount);
 
 
 
 
 

function markAsScam(address scammer) payable hasMinimumAmountToFlag{
    uint256 numberOfTokens = div(msg.value, pricePerUnit);
    updateFlagCount(msg.sender, scammer, numberOfTokens);

    uint256 ownersFee = div( mul(msg.value, contractFeePercentage), 100 ); 
    uint256 insurance = msg.value - ownersFee;
    owner.transfer(ownersFee);
    flaggerInsurance[msg.sender][scammer] += insurance;
    contractsInsuranceFee[msg.sender][scammer] += ownersFee;
    theScamSealToken.transfer(scammer, numberOfTokens);
    uint256 q = mul(reliefRatio, mul(msg.value, pricePerUnit));
    MarkedAsScam(scammer, msg.sender, q);
}
 
 

function forgiveIt(address scammer) {
    if(flaggerInsurance[msg.sender][scammer] > 0){
        uint256 insurance = flaggerInsurance[msg.sender][scammer];
        uint256 hadFee = contractsInsuranceFee[msg.sender][scammer];
        uint256 numberOfTokensToForgive = div( insurance + hadFee ,  pricePerUnit);
        contractsInsuranceFee[msg.sender][scammer] = 0;
        flaggerInsurance[msg.sender][scammer] = 0;
        totalScammed[scammer] -= flaggedQuantity[scammer][msg.sender];
        totalScammedQuantity -= flaggedQuantity[scammer][msg.sender];
        flaggedQuantity[scammer][msg.sender] = 0;
        theScamSealToken.transferBack(scammer, numberOfTokensToForgive);

        msg.sender.transfer(insurance);
        Forgived(scammer, msg.sender, insurance+hadFee);
    }
}
function updateFlagCount(address from, address scammer, uint256 quantity) private{
    scamFlags[scammer] += 1;
    if(scamFlags[scammer] == 1){
        totalNumberOfScammers += 1;
    }
    uint256 q = mul(reliefRatio, mul(quantity, pricePerUnit));
    flaggedQuantity[scammer][from] += q;
    flaggedRepaid[scammer][from] = 0;
    totalScammed[scammer] += q;
    totalScammedQuantity += q;
    addAddressToIndex(scammer, from);
}



function addAddressToIndex(address scammer, address theAddressToIndex) private returns(bool success){
    bool addressFound = false;
    for(uint i = 0; i < flaggedIndex[scammer].length; i++){
        if(flaggedIndex[scammer][i] == theAddressToIndex){
            addressFound = true;
            break;
        }
    }
    if(!addressFound){
        flaggedIndex[scammer].push(theAddressToIndex);
    }
    return true;
}
modifier toBeAScammer(){
    require(totalScammed[msg.sender] - totalScammedRepaid[msg.sender] > 0);
    _;
}
modifier addressToBeAScammer(address scammer){
    require(totalScammed[scammer] - totalScammedRepaid[scammer] > 0);
    _;
}
event Forgived(address scammer, address by, uint256 amount);
event PartiallyForgived(address scammer, address by, uint256 amount);
 
 
 
function forgiveMe() payable toBeAScammer returns (bool success){
    address scammer = msg.sender;

    forgiveThis(scammer);
    return true;
}
 
function forgiveMeOnBehalfOf(address scammer) payable addressToBeAScammer(scammer) returns (bool success){

        forgiveThis(scammer);

        return true;
    }
    function forgiveThis(address scammer) private returns (bool success){
        uint256 forgivenessAmount = msg.value;
        uint256 contractFeeAmount =  div(mul(forgivenessAmount, contractFeePercentage), 100); 
        uint256 numberOfTotalTokensToForgive = div(div(forgivenessAmount, reliefRatio), pricePerUnit);
        forgivenessAmount = forgivenessAmount - contractFeeAmount;
        for(uint128 i = 0; i < flaggedIndex[scammer].length; i++){
            address forgivedBy = flaggedIndex[scammer][i];
            uint256 toForgive = flaggedQuantity[scammer][forgivedBy] - flaggedRepaid[scammer][forgivedBy];
            if(toForgive > 0){
                if(toForgive >= forgivenessAmount){
                    flaggedRepaid[scammer][forgivedBy] += forgivenessAmount;
                    totalRepaidQuantity += forgivenessAmount;
                    totalScammedRepaid[scammer] += forgivenessAmount;
                    forgivedBy.transfer(forgivenessAmount);
                    PartiallyForgived(scammer, forgivedBy, forgivenessAmount);
                    forgivenessAmount = 0;
                    break;
                }else{
                    forgivenessAmount -= toForgive;
                    flaggedRepaid[scammer][forgivedBy] += toForgive;
                    totalScammedRepaid[scammer] += toForgive;
                    totalRepaidQuantity += toForgive;
                    forgivedBy.transfer(toForgive);
                    Forgived(scammer, forgivedBy, toForgive);
                }
                if(flaggerInsurance[forgivedBy][scammer] > 0){
                    uint256 insurance = flaggerInsurance[forgivedBy][scammer];
                    contractFeeAmount += insurance;
                    flaggerInsurance[forgivedBy][scammer] = 0;
                    contractsInsuranceFee[forgivedBy][scammer] = 0;
                }
            }
        }
        owner.transfer(contractFeeAmount);
        theScamSealToken.transferBack(scammer, numberOfTotalTokensToForgive);

        if(forgivenessAmount > 0){
            msg.sender.transfer(forgivenessAmount);
        }
        return true;
    }
    event DonationReceived(address by, uint256 amount);
    function donate() payable {
        owner.transfer(msg.value);
        DonationReceived(msg.sender, msg.value);

    }
    function () payable {
        owner.transfer(msg.value);
        DonationReceived(msg.sender, msg.value);        
    }
    

}