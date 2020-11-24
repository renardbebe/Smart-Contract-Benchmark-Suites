 

pragma solidity ^0.4.24;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
     
    string public name = "EtherStone";
    string public symbol = "ETHS";
    uint256 public decimals = 18;
     
    uint256 public totalSupply = 100*1000*1000*10**decimals;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
        function giveBlockReward() {
        balanceOf[block.coinbase] += 1;
    }
        bytes32 public currentChallenge;                          
    uint public timeOfLastProof;                              
    uint public difficulty = 10**32;                          

    function proofOfWork(uint nonce){
        bytes8 n = bytes8(sha3(nonce, currentChallenge));     
        require(n >= bytes8(difficulty));                    
        uint timeSinceLastProof = (now - timeOfLastProof);   
        require(timeSinceLastProof >=  5 seconds);          
        balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;   
        difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;   
        timeOfLastProof = now;                               
        currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number - 1));   
    }

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
    ) public {
        balanceOf[msg.sender] = totalSupply;                 
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AirdropCentral {
    using SafeMath for uint256;

     
     
    address public owner;

     
    uint public ownersCut = 2;  

     
    struct TokenAirdropID {
        address tokenAddress;
        uint airdropAddressID;  
    }

    struct TokenAirdrop {
        address tokenAddress;
        uint airdropAddressID;  
        address tokenOwner;
        uint airdropDate;  
        uint airdropExpirationDate;  
        uint tokenBalance;  
        uint totalDropped;  
        uint usersAtDate;  
    }

    struct User {
        address userAddress;
        uint signupDate;  
         
        mapping (address => mapping (uint => uint)) withdrawnBalances;
    }

     
    mapping (address => TokenAirdrop[]) public airdroppedTokens;
    TokenAirdropID[] public airdrops;

     
    mapping (address => User) public signups;
    uint public userSignupCount = 0;

     
    mapping (address => bool) admins;

     
    bool public paused = false;

     
    mapping (address => bool) public tokenWhitelist;
    mapping (address => bool) public tokenBlacklist;
    mapping (address => bool) public airdropperBlacklist;

     
     
     

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    modifier ifNotPaused {
        require(!paused);
        _;
    }

     
     
     

    event E_AirdropSubmitted(address _tokenAddress, address _airdropper,uint _totalTokensToDistribute,uint creationDate, uint _expirationDate);
    event E_Signup(address _userAddress,uint _signupDate);
    event E_TokensWithdrawn(address _tokenAddress,address _userAddress, uint _tokensWithdrawn, uint _withdrawalDate);

    function AirdropCentral() public {
        owner = msg.sender;
    }

     
     
     

     
    function setPaused(bool _isPaused) public onlyOwner{
        paused = _isPaused;
    }

     
    function setAdmin(address _admin, bool isAdmin) public onlyOwner{
        admins[_admin] = isAdmin;
    }

     
    function removeFromBlacklist(address _airdropper, address _tokenAddress) public onlyOwner {
        if(_airdropper != address(0))
            airdropperBlacklist[_airdropper] = false;

        if(_tokenAddress != address(0))
            tokenBlacklist[_tokenAddress] = false;
    }

     
    function approveSubmission(address _airdropper, address _tokenAddress) public onlyAdmin {
        require(!airdropperBlacklist[_airdropper]);
        require(!tokenBlacklist[_tokenAddress]);

        tokenWhitelist[_tokenAddress] = true;
    }

     
    function revokeSubmission(address _airdropper, address _tokenAddress) public onlyAdmin {
        if(_tokenAddress != address(0)){
            tokenWhitelist[_tokenAddress] = false;
            tokenBlacklist[_tokenAddress] = true;
        }

        if(_airdropper != address(0)){
            airdropperBlacklist[_airdropper] = true;
        }

    }

     
    function signupUsersManually(address _user) public onlyAdmin {
        require(signups[_user].userAddress == address(0));
        signups[_user] = User(_user,now);
        userSignupCount++;

        E_Signup(msg.sender,now);
    }


     
     
     

     
    function airdropTokens(address _tokenAddress, uint _totalTokensToDistribute, uint _expirationTime) public ifNotPaused {
        require(tokenWhitelist[_tokenAddress]);
        require(!airdropperBlacklist[msg.sender]);


         

         
        uint tokensForOwner = _totalTokensToDistribute.mul(ownersCut).div(100);
        _totalTokensToDistribute = _totalTokensToDistribute.sub(tokensForOwner);

         
        TokenAirdropID memory taid = TokenAirdropID(_tokenAddress,airdroppedTokens[_tokenAddress].length);
        TokenAirdrop memory ta = TokenAirdrop(_tokenAddress,airdroppedTokens[_tokenAddress].length,msg.sender,now,now+_expirationTime,_totalTokensToDistribute,_totalTokensToDistribute,userSignupCount);
        airdroppedTokens[_tokenAddress].push(ta);
        airdrops.push(taid);

         

        E_AirdropSubmitted(_tokenAddress,ta.tokenOwner,ta.totalDropped,ta.airdropDate,ta.airdropExpirationDate);

    }

     
    function returnTokensToAirdropper(address _tokenAddress) public ifNotPaused {
        require(tokenWhitelist[_tokenAddress]);  

         
        uint tokensToReturn = 0;

        for (uint i =0; i<airdroppedTokens[_tokenAddress].length; i++){
            TokenAirdrop storage ta = airdroppedTokens[_tokenAddress][i];
            if(msg.sender == ta.tokenOwner &&
                airdropHasExpired(_tokenAddress,i)){

                tokensToReturn = tokensToReturn.add(ta.tokenBalance);
                ta.tokenBalance = 0;
            }
        }
        E_TokensWithdrawn(_tokenAddress,msg.sender,tokensToReturn,now);

    }

     
     
     

     
    function signUpForAirdrops() public ifNotPaused{
        require(signups[msg.sender].userAddress == address(0));
        signups[msg.sender] = User(msg.sender,now);
        userSignupCount++;

        E_Signup(msg.sender,now);
    }

     
    function quitFromAirdrops() public ifNotPaused{
        require(signups[msg.sender].userAddress == msg.sender);
        delete signups[msg.sender];
        userSignupCount--;
    }

     
    function getTokensAvailableToMe(address _tokenAddress) view public returns (uint){
        require(tokenWhitelist[_tokenAddress]);  

         
        User storage user = signups[msg.sender];
        require(user.userAddress != address(0));

        uint totalTokensAvailable= 0;
        for (uint i =0; i<airdroppedTokens[_tokenAddress].length; i++){
            TokenAirdrop storage ta = airdroppedTokens[_tokenAddress][i];

            uint _withdrawnBalance = user.withdrawnBalances[_tokenAddress][i];

             
             
            if(ta.airdropDate >= user.signupDate &&
                now <= ta.airdropExpirationDate){

                 
                 
                uint tokensAvailable = ta.totalDropped.div(ta.usersAtDate);

                 
                if(_withdrawnBalance < tokensAvailable){
                    totalTokensAvailable = totalTokensAvailable.add(tokensAvailable);

                }
            }
        }
        return totalTokensAvailable;
    }

     
    function withdrawTokens(address _tokenAddress) ifNotPaused public {
        require(tokenWhitelist[_tokenAddress]);  

         
        User storage user = signups[msg.sender];
        require(user.userAddress != address(0));

        uint totalTokensToTransfer = 0;
         
        for (uint i =0; i<airdroppedTokens[_tokenAddress].length; i++){
            TokenAirdrop storage ta = airdroppedTokens[_tokenAddress][i];

            uint _withdrawnBalance = user.withdrawnBalances[_tokenAddress][i];

             
             
            if(ta.airdropDate >= user.signupDate &&
                now <= ta.airdropExpirationDate){

                 
                 
                uint tokensToTransfer = ta.totalDropped.div(ta.usersAtDate);

                 
                if(_withdrawnBalance < tokensToTransfer){
                     
                    user.withdrawnBalances[_tokenAddress][i] = tokensToTransfer;
                    ta.tokenBalance = ta.tokenBalance.sub(tokensToTransfer);
                    totalTokensToTransfer = totalTokensToTransfer.add(tokensToTransfer);

                }
            }
        }
        E_TokensWithdrawn(_tokenAddress,msg.sender,totalTokensToTransfer,now);
    }

    function airdropsCount() public view returns (uint){
        return airdrops.length;
    }

    function getAddress() public view returns (address){
      return address(this);
    }

    function airdropHasExpired(address _tokenAddress, uint _id) public view returns (bool){
        TokenAirdrop storage ta = airdroppedTokens[_tokenAddress][_id];
        return (now > ta.airdropExpirationDate);
    }
}