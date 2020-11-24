 

 
pragma solidity ^0.4.11;

 
contract ZeePinToken  {
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;


    string public name = "ZeePin Token";
    string public symbol = "ZPT";
    uint public decimals = 18;

    uint public startTime;  
    uint public endTime;  
    uint public startEarlyBird;   
    uint public endEarlyBird;   
    uint public startPeTime;   
    uint public endPeTime;  
    uint public endFirstWeek;
    uint public endSecondWeek;
    uint public endThirdWeek;
    uint public endFourthWeek;
    uint public endFifthWeek;


     
     
    address public founder = 0x0;

     
     
    address public signer = 0x0;

     
    uint256 public pePrice = 6160;
    uint256 public earlyBirdPrice = 5720;
    uint256 public firstWeekTokenPrice = 4840;
    uint256 public secondWeekTokenPrice = 4752;
    uint256 public thirdWeekTokenPrice = 4620;
    uint256 public fourthWeekTokenPrice = 4532;
    uint256 public fifthWeekTokenPrice = 4400;

    uint256 public etherCap = 90909 * 10**decimals;  
    uint256 public totalMintedToken = 1000000000;
    uint256 public etherLowLimit = 16500 * 10**decimals;
    uint256 public earlyBirdCap = 6119 * 10**decimals;
    uint256 public earlyBirdMinPerPerson = 5 * 10**decimals;
    uint256 public earlyBirdMaxPerPerson = 200 * 10**decimals;
    uint256 public peCap = 2700 * 10**decimals;
    uint256 public peMinPerPerson = 150 * 10**decimals;
    uint256 public peMaxPerPerson = 450 * 10**decimals;
    uint256 public regularMinPerPerson = 1 * 10**17;
    uint256 public regularMaxPerPerson = 200 * 10**decimals;

    uint public transferLockup = 15 days ;  

    uint public founderLockup = 2 weeks;  
    

    uint256 public founderAllocation = 100 * 10**16;  


    bool public founderAllocated = false;  

    uint256 public saleTokenSupply = 0;  
    uint256 public saleEtherRaised = 0;  
    bool public halted = false;  

    event Buy(uint256 eth, uint256 fbt);
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event print(bytes32 msg);

     
    function ZeePinToken(address founderInput, address signerInput, uint startTimeInput, uint endTimeInput, uint startEarlyBirdInput, uint endEarlyBirdInput, uint startPeInput, uint endPeInput) {
        founder = founderInput;
        signer = signerInput;
        startTime = startTimeInput;
        endTime = endTimeInput;
        startEarlyBird = startEarlyBirdInput;
        endEarlyBird = endEarlyBirdInput;
        startPeTime = startPeInput;
        endPeTime = endPeInput;
        
        endFirstWeek = startTime + 1 weeks;
        endSecondWeek = startTime + 2 weeks;
        endThirdWeek = startTime + 3 weeks;
        endFourthWeek = startTime + 4 weeks;
        endFifthWeek = startTime + 5 weeks;
    }

     
    function price() constant returns(uint256) {
        if (now <= endEarlyBird && now >= startEarlyBird) return earlyBirdPrice;
        if (now <= endFirstWeek) return firstWeekTokenPrice;
        if (now <= endSecondWeek) return secondWeekTokenPrice;
        if (now <= endThirdWeek) return thirdWeekTokenPrice;
        if (now <= endFourthWeek) return fourthWeekTokenPrice;
        if (now <= endFifthWeek) return fifthWeekTokenPrice;
        return fifthWeekTokenPrice;
    }

     
    function testPrice(uint256 currentTime) constant returns(uint256) {
        if (currentTime < endEarlyBird && currentTime >= startEarlyBird) return earlyBirdPrice;
        if (currentTime < endFirstWeek && currentTime >= startTime) return firstWeekTokenPrice;
        if (currentTime < endSecondWeek && currentTime >= endFirstWeek) return secondWeekTokenPrice;
        if (currentTime < endThirdWeek && currentTime >= endSecondWeek) return thirdWeekTokenPrice;
        if (currentTime < endFourthWeek && currentTime >= endThirdWeek) return fourthWeekTokenPrice;
        if (currentTime < endFifthWeek && currentTime >= endFourthWeek) return fifthWeekTokenPrice;
        return fifthWeekTokenPrice;
    }


     
    function buy( bytes32 hash) payable {
        print(hash);
        if (((now < startTime || now >= endTime) && (now < startEarlyBird || now >= endEarlyBird)) || halted) revert();
        if (now>=startEarlyBird && now<endEarlyBird) {
            if (msg.value < earlyBirdMinPerPerson || msg.value > earlyBirdMaxPerPerson || (saleEtherRaised + msg.value) > (peCap + earlyBirdCap)) {
                revert();
            }
        }
        if (now>=startTime && now<endTime) {
            if (msg.value < regularMinPerPerson || msg.value > regularMaxPerPerson || (saleEtherRaised + msg.value) > etherCap ) {
                revert();
            }
        }
        uint256 tokens = (msg.value * price());
        balances[msg.sender] = (balances[msg.sender] + tokens);
        totalSupply = (totalSupply + tokens);
        saleEtherRaised = (saleEtherRaised + msg.value);

        if (!founder.call.value(msg.value)()) revert();  

        Buy(msg.value, tokens);
    }

     
    function allocateFounderTokens() {
        if (msg.sender!=founder) revert();
        if (now <= endTime + founderLockup) revert();
        if (founderAllocated) revert();
        balances[founder] = (balances[founder] + totalSupply * founderAllocation / (1 ether));
        totalSupply = (totalSupply + totalSupply * founderAllocation / (1 ether));
        founderAllocated = true;
        AllocateFounderTokens(msg.sender);
    }

     
    function offlineSales(uint256 offlineNum, uint256 offlineEther) {
        if (msg.sender!=founder) revert();
         
        if (saleEtherRaised + offlineEther > etherCap) revert();
        totalSupply = (totalSupply + offlineNum);
        balances[founder] = (balances[founder] + offlineNum );
        saleEtherRaised = (saleEtherRaised + offlineEther);
    }

     
    function halt() {
        if (msg.sender!=founder) revert();
        halted = true;
    }

    function unhalt() {
        if (msg.sender!=founder) revert();
        halted = false;
    }

     
    function changeFounder(address newFounder) {
        if (msg.sender!=founder) revert();
        founder = newFounder;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (now <= endTime + transferLockup) revert();

         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }

    }
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (msg.sender != founder) revert();

         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

     
    function() payable {
        buy(0x33);
    }

     
    function kill() { 
        if (msg.sender == founder) suicide(founder); 
    }

}