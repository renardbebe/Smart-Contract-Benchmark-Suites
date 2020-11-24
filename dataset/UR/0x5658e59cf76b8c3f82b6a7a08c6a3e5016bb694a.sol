 

pragma solidity ^0.4.25;

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

     
    mapping(address => IntelState[]) public intelsByProvider;
    
     
    mapping(address => uint) public balances;

     
    mapping(address => bool) public registered; 

     
    address[] public participants;

     
    uint public totalParetoBalance; 

    uint[] intelIndexes;
    
     
    uint public intelCount; 
    
     
    address public owner;    
    
     
    ERC20 public token;  

     
    address public paretoAddress;

    
    constructor(address _owner, address _token) public {
         
        owner = _owner; 
        token = ERC20(_token);
        paretoAddress = _token;
    }
    

     
    modifier onlyOwner(){
        require(msg.sender == owner, "Sender of this transaction can be only the owner");
        _;
    }


    function changeOwner(address _newOwner) public onlyOwner{
        require(_newOwner != address(0x0), "New owner address is not valid");
        owner = _newOwner;
    }
    

    event Reward( address sender, uint intelIndex, uint rewardAmount);
    event NewIntel(address intelProvider, uint depositAmount, uint desiredReward, uint intelID, uint ttl);
    event RewardDistributed(uint intelIndex, uint provider_amount, address provider, address distributor, uint distributor_amount);
    event LogProxy(address destination, address account, uint amount, uint gasLimit);
    event Deposited(address from, address to, uint amount);
    
    function makeDeposit(address _address, uint _amount) public {
        require(_address != address(0x0), "Address is invalid");
        require(_amount > 0, "Deposit amount needs to be greater than 0");

         
        token.transferFrom(_address, address(this), _amount);

         
        balances[_address] = balances[_address].add(_amount); 

         
         
         
        if(!registered[_address]) {     
            participants.push(_address);
            registered[_address] = true;
        }

         
        totalParetoBalance = totalParetoBalance.add(_amount);  
        
		 
        emit Deposited(_address, address(this), _amount);
    }
    
     
     
     
     
     
     
     
     
    function create(address intelProvider, uint depositAmount, uint desiredReward, uint intelID, uint ttl) public {

        require(intelID > 0, "Intel's ID should be greater than 0.");
        require(address(intelProvider) != address(0x0), "Intel Provider's address provided is invalid.");
        require(depositAmount > 0, "Amount should be greater than 0.");
        require(desiredReward > 0, "Desired reward should be greater than 0.");
        require(ttl > now, "Expiration date for Intel should be greater than now.");
                
        IntelState storage intel = intelDB[intelID];
        require(intel.depositAmount == 0, "Intel with the provided ID already exists");

         
        if(depositAmount <= balances[intelProvider]) {                      

             
            balances[intelProvider] = balances[intelProvider].sub(depositAmount);   

             
            balances[address(this)] = balances[address(this)].add(depositAmount);   

        } else {
             
            token.transferFrom(intelProvider, address(this), depositAmount);  

             
            balances[address(this)] = balances[address(this)].add(depositAmount); 
   
             
            totalParetoBalance = totalParetoBalance.add(depositAmount);   
        }

         
        address[] memory contributionsList;

         
        IntelState memory newIntel = IntelState(intelProvider, depositAmount, desiredReward, depositAmount, intelID, ttl, false, contributionsList);

         
        intelDB[intelID] = newIntel;

         
        intelsByProvider[intelProvider].push(newIntel);

         
        intelIndexes.push(intelID);

         
        intelCount++;
     
         
        emit NewIntel(intelProvider, depositAmount, desiredReward, intelID, ttl);
    }
    

    
     
     
     
     
     
     
    function sendReward(uint intelIndex, uint rewardAmount) public returns(bool success){

         
        require(intelIndex > 0, "Intel's ID should be greater than 0.");

		 
        require(rewardAmount > 0, "Reward amount should be greater than 0.");

        IntelState storage intel = intelDB[intelIndex];

         
        require(intel.intelProvider != address(0x0), "Intel for the provided ID does not exist.");
        
         
        require(msg.sender != intel.intelProvider, "msg.sender should not be the current Intel's provider."); 
        
         
        require(intel.rewardAfter > now, "Intel is expired");  

         
        require(!intel.rewarded, "Intel is already rewarded"); 
     
         
        if(rewardAmount <= balances[msg.sender]) {      
             
             
            balances[msg.sender] = balances[msg.sender].sub(rewardAmount);  
            
             
            balances[address(this)] = balances[address(this)].add(rewardAmount); 
        } else {

             
            token.transferFrom(msg.sender, address(this), rewardAmount); 

             
            balances[address(this)] = balances[address(this)].add(rewardAmount);

             
            totalParetoBalance = totalParetoBalance.add(rewardAmount);   
        }

         
        intel.balance = intel.balance.add(rewardAmount);

         
        if(intel.contributions[msg.sender] == 0){
            intel.contributionsList.push(msg.sender);
        }
        
         
        intel.contributions[msg.sender] = intel.contributions[msg.sender].add(rewardAmount);
        

         
        emit Reward(msg.sender, intelIndex, rewardAmount);


        return true;
    }
    

    
     
     
     
     
     
    function distributeReward(uint intelIndex) public returns(bool success){

        require(intelIndex > 0, "Intel's ID should be greater than 0.");
        

        IntelState storage intel = intelDB[intelIndex];
        
        require(!intel.rewarded, "Intel is already rewarded.");
        require(now >= intel.rewardAfter, "Intel needs to be expired for distribution.");
        

        intel.rewarded = true;
        uint distributed_amount = 0;

        distributed_amount = intel.balance;
        
        balances[address(this)] = balances[address(this)].sub(distributed_amount);   
        intel.balance = 0;

        uint fee = distributed_amount.div(10);     
        distributed_amount = distributed_amount.sub(fee);    

        token.transfer(msg.sender, fee/2);   
        balances[owner] = balances[owner].add(fee/2);   
        token.transfer(intel.intelProvider, distributed_amount);  
        totalParetoBalance = totalParetoBalance.sub(distributed_amount.add(fee/2));  
       

        emit RewardDistributed(intelIndex, distributed_amount, intel.intelProvider, msg.sender, fee);


        return true;

    }
    
    function getParetoBalance(address _address) public view returns(uint) {
        return balances[_address];
    }

    function distributeFeeRewards(address[] _participants, uint _amount) public onlyOwner {
        uint totalCirculatingAmount = totalParetoBalance - balances[address(this)] - balances[owner];

        for( uint i = 0; i < _participants.length; i++) {
            if(balances[_participants[i]] > 0) {
                uint amountToAdd = _amount.mul(balances[_participants[i]]).div(totalCirculatingAmount);
                balances[_participants[i]] = balances[_participants[i]].add(amountToAdd);
                balances[owner] = balances[owner].sub(amountToAdd);
            }
        }
    }

    function getParticipants() public view returns(address[] memory _participants) {
        _participants = new address[](participants.length);
        
        for(uint i = 0; i < participants.length; i++) {
            _participants[i] = participants[i];
        }
        return;
    }

     
     
     
     
    function setParetoToken(address _token) public onlyOwner{

        token = ERC20(_token);
        paretoAddress = _token;

    }
    

    
     
     
     
     
     
     
     
    function proxy(address destination, address account, uint amount, uint gasLimit) public onlyOwner{

        require(destination != paretoAddress, "Pareto Token cannot be assigned as destination.");     

         
         
         
         


         


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
        
        uint length = intelsByProvider[_provider].length;

        intelID = new uint[](length);
        intelProvider = new address[](length);
        depositAmount = new uint[](length);
        desiredReward = new uint[](length);
        balance = new uint[](length);
        rewardAfter = new uint[](length);
        rewarded = new bool[](length);

        IntelState[] memory intels = intelsByProvider[_provider];

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

    function contributionsByIntel(uint intelIndex) public view returns(address[] memory addresses, uint[] memory amounts){
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