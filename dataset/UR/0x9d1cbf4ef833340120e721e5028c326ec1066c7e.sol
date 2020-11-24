 

pragma solidity 0.5.1;   

 
 
 
     
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


 
 
 
    
    contract owned {
        address payable public owner;
        
         constructor () public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address payable newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata  _extraData) external; }


 
 
 
    
    contract TokenERC20 {
         
        using SafeMath for uint256;
        string public name;
        string public symbol;
        uint8 public decimals = 18;  
        uint256 public totalSupply;
        bool public safeguard = false;   
    
         
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
         
        event Transfer(address indexed from, address indexed to, uint256 value);
    
         
        event Burn(address indexed from, uint256 value);
    
         
        constructor (
            uint256 initialSupply,
            string memory tokenName,
            string memory tokenSymbol
        ) public {
            
            totalSupply = initialSupply * 1 ether;       
            uint256 halfTotalSupply = totalSupply / 2;   
            
            balanceOf[msg.sender] = halfTotalSupply;     
            balanceOf[address(this)] = halfTotalSupply;  
            name = tokenName;                            
            symbol = tokenSymbol;                        
            
            emit Transfer(address(0x0), msg.sender, halfTotalSupply);    
            emit Transfer(address(0x0), address(this), halfTotalSupply); 
        }
    
         
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
             
            require(_to != address(0x0));
             
            require(balanceOf[_from] >= _value);
             
            require(balanceOf[_to].add(_value) > balanceOf[_to]);
             
            uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
             
            balanceOf[_from] = balanceOf[_from].sub(_value);
             
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
             
            assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        }
    
         
        function transfer(address _to, uint256 _value) public returns (bool success) {
            _transfer(msg.sender, _to, _value);
            return true;
        }
    
         
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            require(!safeguard);
            require(_value <= allowance[_from][msg.sender]);      
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            _transfer(_from, _to, _value);
            return true;
        }
    
         
        function approve(address _spender, uint256 _value) public
            returns (bool success) {
            require(!safeguard);
            allowance[msg.sender][_spender] = _value;
            return true;
        }
    
         
        function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
            public
            returns (bool success) {
            require(!safeguard);
            tokenRecipient spender = tokenRecipient(_spender);
            if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, address(this), _extraData);
                return true;
            }
        }
    
         
        function burn(uint256 _value) public returns (bool success) {
            require(!safeguard);
            require(balanceOf[msg.sender] >= _value);    
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
            totalSupply = totalSupply.sub(_value);                       
            emit Burn(msg.sender, _value);
            return true;
        }
    
         
        function burnFrom(address _from, uint256 _value) public returns (bool success) {
            require(!safeguard);
            require(balanceOf[_from] >= _value);                 
            require(_value <= allowance[_from][msg.sender]);     
            balanceOf[_from] = balanceOf[_from].sub(_value);                          
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);              
            totalSupply = totalSupply.sub(_value);                               
            emit  Burn(_from, _value);
            return true;
        }
        
    }
    
 
 
 
    
    contract DoubleEther is owned, TokenERC20 {
        
        
         
         
         
    
         
        string internal tokenName = "Double Ether";
        string internal tokenSymbol = "DET";
        uint256 internal initialSupply = 100000000;   
        
        
         
        mapping (address => bool) public frozenAccount;
        
         
        event FrozenFunds(address target, bool frozen);
    
         
        constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

         
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
            require (_to != address(0x0));                       
            require (balanceOf[_from] >= _value);                
            require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
            require(!frozenAccount[_from]);                      
            require(!frozenAccount[_to]);                        
            balanceOf[_from] = balanceOf[_from].sub(_value);     
            balanceOf[_to] = balanceOf[_to].add(_value);         
            emit Transfer(_from, _to, _value);
        }
        
         
         
         
        function freezeAccount(address target, bool freeze) onlyOwner public {
                frozenAccount[target] = freeze;
            emit  FrozenFunds(target, freeze);
        }
        
         
        function changeSafeguardStatus() onlyOwner public{
            if (safeguard == false){
                safeguard = true;
            }
            else{
                safeguard = false;    
            }
        }



         
         
         

        
        uint256 public returnPercentage = 150;   
        uint256 public additionalFund = 0;
        address payable[] public winnerQueueAddresses;
        uint256[] public winnerQueueAmount;
        
         
        event Deposit(address indexed depositor, uint256 depositAmount);
        
         
        event RewardPaid(address indexed rewardPayee, uint256 rewardAmount);
        
        function showPeopleInQueue() public view returns(uint256) {
            return winnerQueueAmount.length;
        }
        
         
        function () payable external {
            require(!safeguard);
            require(!frozenAccount[msg.sender]);
            require(msg.value >= 0.5 ether);
            
             
            uint256 _depositedEther;
            if(msg.value >= 3 ether){
                _depositedEther = 3 ether;
                additionalFund += msg.value - 3 ether; 
            }
            else{
                _depositedEther = msg.value;
            }
            
            
             
            uint256 TotalPeopleInQueue = winnerQueueAmount.length;
            for(uint256 index = 0; index < TotalPeopleInQueue; index++){
                
                if(winnerQueueAmount[0] <= (address(this).balance - additionalFund) ){
                    
                     
                    winnerQueueAddresses[0].transfer(winnerQueueAmount[0]);
                    _transfer(address(this), winnerQueueAddresses[0], winnerQueueAmount[0]*100/returnPercentage);
                    
                     
                    for (uint256 i = 0; i<winnerQueueAmount.length-1; i++){
                        winnerQueueAmount[i] = winnerQueueAmount[i+1];
                        winnerQueueAddresses[i] = winnerQueueAddresses[i+1];
                    }
                    winnerQueueAmount.length--;
                    winnerQueueAddresses.length--;
                }
                else{
                     
                    break;
                }
            }
            
             
            winnerQueueAddresses.push(msg.sender); 
            winnerQueueAmount.push(_depositedEther * returnPercentage / 100);
            emit Deposit(msg.sender, msg.value);
        }

    

         
        function manualWithdrawEtherAll() onlyOwner public{
            address(owner).transfer(address(this).balance);
        }
        
         
        function manualWithdrawEtherAdditionalOnly() onlyOwner public{
            additionalFund = 0;
            address(owner).transfer(additionalFund);
        }
        
         
        function manualWithdrawTokens(uint tokenAmount) onlyOwner public{
             
            _transfer(address(this), address(owner), tokenAmount);
        }
        
         
        function destructContract()onlyOwner public{
            selfdestruct(owner);
        }
        
         
         
        function removeAddressFromQueue(uint256 index) onlyOwner public {
            require(index <= winnerQueueAmount.length);
            additionalFund +=  winnerQueueAmount[index];
             
            for (uint256 i = index; i<winnerQueueAmount.length-1; i++){
                winnerQueueAmount[i] = winnerQueueAmount[i+1];
                winnerQueueAddresses[i] = winnerQueueAddresses[i+1];
            }
            winnerQueueAmount.length--;
            winnerQueueAddresses.length--;
        } 

         
        function restartTheQueue() onlyOwner public {
             
            uint256 arrayLength = winnerQueueAmount.length;
            if(arrayLength < 35){
                 
                for(uint256 i = 0; i < arrayLength; i++){
                    _transfer(address(this), winnerQueueAddresses[i], winnerQueueAmount[i]*200*100/returnPercentage);
                }
                 
                winnerQueueAddresses = new address payable[](0);
                winnerQueueAmount = new uint256[](0);
            }
            else{
                 
                 
                for(uint256 i = 0; i < 35; i++){
                     
                    _transfer(address(this), winnerQueueAddresses[i], winnerQueueAmount[i]*200*100/returnPercentage);
                    
                     
                    for (uint256 j = 0; j<arrayLength-i-1; j++){
                        winnerQueueAmount[j] = winnerQueueAmount[j+1];
                        winnerQueueAddresses[j] = winnerQueueAddresses[j+1];
                    }
                }
                 
                winnerQueueAmount.length -= 35;
                winnerQueueAddresses.length -= 35;
            }
        }

}