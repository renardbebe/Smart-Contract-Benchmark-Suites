 

pragma solidity 0.4.25;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
 
 
contract Intel{
    
    using SafeMath for uint256;
    
    struct IntelState {
        address intelProvider;
        uint depositAmount;
        uint desiredReward;
         
         
        uint balance;
        uint intelID;
         
        uint rewardAfter;
         
        bool rewarded;
                 
         
        address[] contributionsList;
        mapping(address => uint) contributions;

    }


    mapping(uint => IntelState) intelDB;
    mapping(address => IntelState[]) public IntelsByProvider;
    uint[] intelIndexes;
    
    uint public intelCount;
    

    address public owner;     
    
    ERC20 public token;    
    address public ParetoAddress;

    
    constructor(address _owner, address _token) public {
        owner = _owner;   
        token = ERC20(_token);
        ParetoAddress = _token;
    }
    

     
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    

    event Reward( address sender, uint intelIndex, uint rewardAmount);
    event NewIntel(address intelProvider, uint depositAmount, uint desiredReward, uint intelID, uint ttl);
    event RewardDistributed(uint intelIndex, uint provider_amount, address provider, address distributor, uint distributor_amount);
    event LogProxy(address destination, address account, uint amount, uint gasLimit);
    

     
     
     
     
     
     
     
     
     
    function create(address intelProvider, uint depositAmount, uint desiredReward, uint intelID, uint ttl) public {

        require(address(intelProvider) != address(0x0));
        require(depositAmount > 0);
        require(desiredReward > 0);
        require(ttl > now);
        
        token.transferFrom(intelProvider, address(this), depositAmount);   
        
        address[] memory contributionsList;
        IntelState memory newIntel = IntelState(intelProvider, depositAmount, desiredReward, depositAmount, intelID, ttl, false, contributionsList);
        intelDB[intelID] = newIntel;
        IntelsByProvider[intelProvider].push(newIntel);

        intelIndexes.push(intelID);
        intelCount++;
        

        emit NewIntel(intelProvider, depositAmount, desiredReward, intelID, ttl);
        
    }
    

     
     
     
     
     
     
     
    function sendReward(uint intelIndex, uint rewardAmount) public returns(bool success){

        IntelState storage intel = intelDB[intelIndex];
        require(intel.intelProvider != address(0x0));   
        require(msg.sender != intel.intelProvider);  
        require(intel.rewardAfter > now);        
        require(!intel.rewarded);   
        

        token.transferFrom(msg.sender, address(this), rewardAmount);   
        intel.balance = intel.balance.add(rewardAmount);

        if(intel.contributions[msg.sender] == 0){
            intel.contributionsList.push(msg.sender);
        }
        
        intel.contributions[msg.sender] = intel.contributions[msg.sender].add(rewardAmount);
        

        emit Reward(msg.sender, intelIndex, rewardAmount);


        return true;

    }
    

     
     
     
     
     
     
    function distributeReward(uint intelIndex) public returns(bool success){

        require(intelIndex > 0);
        

        IntelState storage intel = intelDB[intelIndex];
        
        require(!intel.rewarded);
        require(now >= intel.rewardAfter);
        

        intel.rewarded = true;
        uint distributed_amount = 0;

       


        if (intel.balance > intel.desiredReward){          
            distributed_amount = intel.desiredReward;     

        } else {
            distributed_amount = intel.balance;   
        }

        uint fee = distributed_amount.div(10);     
        distributed_amount = distributed_amount.sub(fee);    

        token.transfer(intel.intelProvider, distributed_amount);  
        token.transfer(msg.sender, fee);                      
        emit RewardDistributed(intelIndex, distributed_amount, intel.intelProvider, msg.sender, fee);


        return true;

    }
    
     
     
     
     
     
    function setParetoToken(address _token) public onlyOwner{

        token = ERC20(_token);
        ParetoAddress = _token;

    }
    

     
     
     
     
     
     
     
     
    function proxy(address destination, address account, uint amount, uint gasLimit) public onlyOwner{

        require(destination != ParetoAddress);     

         
         
         
         


         


        bytes4  sig = bytes4(keccak256("transfer(address,uint256)"));

        assembly {
            let x := mload(0x40)  
        mstore(x,sig)  
        mstore(add(x,0x04),account)
        mstore(add(x,0x24),amount)

        let success := call(       
                            gasLimit,  
                            destination,  
                            0,     
                            x,     
                            0x44,  
                            x,     
                            0x0)  

         
		jumpi(0x02,iszero(success))

        }
        emit LogProxy(destination, account, amount, gasLimit);
    }

     
     
    function() external{
        revert();
    }

     
     
     
     
    function getIntel(uint intelIndex) public view returns(address intelProvider, uint depositAmount, uint desiredReward, uint balance, uint intelID, uint rewardAfter, bool rewarded) {
        
        IntelState storage intel = intelDB[intelIndex];
        intelProvider = intel.intelProvider;
        depositAmount = intel.depositAmount;
        desiredReward = intel.desiredReward;
        balance = intel.balance;
        rewardAfter = intel.rewardAfter;
        intelID = intel.intelID;
        rewarded = intel.rewarded;

    }

    function getAllIntel() public view returns (uint[] intelID, address[] intelProvider, uint[] depositAmount, uint[] desiredReward, uint[] balance, uint[] rewardAfter, bool[] rewarded){
        
        uint length = intelIndexes.length;
        intelID = new uint[](length);
        intelProvider = new address[](length);
        depositAmount = new uint[](length);
        desiredReward = new uint[](length);
        balance = new uint[](length);
        rewardAfter = new uint[](length);
        rewarded = new bool[](length);

        for(uint i = 0; i < intelIndexes.length; i++){
            intelID[i] = intelDB[intelIndexes[i]].intelID;
            intelProvider[i] = intelDB[intelIndexes[i]].intelProvider;
            depositAmount[i] = intelDB[intelIndexes[i]].depositAmount;
            desiredReward[i] = intelDB[intelIndexes[i]].desiredReward;
            balance[i] = intelDB[intelIndexes[i]].balance;
            rewardAfter[i] = intelDB[intelIndexes[i]].rewardAfter;
            rewarded[i] = intelDB[intelIndexes[i]].rewarded;
        }
    }


      function getIntelsByProvider(address _provider) public view returns (uint[] intelID, address[] intelProvider, uint[] depositAmount, uint[] desiredReward, uint[] balance, uint[] rewardAfter, bool[] rewarded){
        
        uint length = IntelsByProvider[_provider].length;

        intelID = new uint[](length);
        intelProvider = new address[](length);
        depositAmount = new uint[](length);
        desiredReward = new uint[](length);
        balance = new uint[](length);
        rewardAfter = new uint[](length);
        rewarded = new bool[](length);

        IntelState[] memory intels = IntelsByProvider[_provider];

        for(uint i = 0; i < length; i++){
            intelID[i] = intels[i].intelID;
            intelProvider[i] = intels[i].intelProvider;
            depositAmount[i] = intels[i].depositAmount;
            desiredReward[i] = intels[i].desiredReward;
            balance[i] = intels[i].balance;
            rewardAfter[i] = intels[i].rewardAfter;
            rewarded[i] = intels[i].rewarded;
        }
    }

    function contributionsByIntel(uint intelIndex) public view returns(address[] addresses, uint[] amounts){
        IntelState storage intel = intelDB[intelIndex];
                
        uint length = intel.contributionsList.length;

        addresses = new address[](length);
        amounts = new uint[](length);

        for(uint i = 0; i < length; i++){
            addresses[i] = intel.contributionsList[i]; 
            amounts[i] = intel.contributions[intel.contributionsList[i]];       
        }

    }

}