 

pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;}
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;}
 function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;}
function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;}}
 
    contract ERC20 {
     function totalSupply() constant returns (uint256 totalSupply);                                  
     function balanceOf(address _owner) constant returns (uint256 balance);                          
     function transfer(address _to, uint256 _value) returns (bool success);                          
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);       
     function approve(address _spender, uint256 _value) returns (bool success);                      
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);      
     function Mine_Block() returns (bool);             
     function Proof_of_Stake() returns (bool);
     function Request_Airdrop() returns (bool);      
     event Mine(address indexed _address, uint _reward);      
     event MinePoS(address indexed _address, uint rewardPoS);
     event MineAD (address indexed _address, uint rewardAD);
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     event SponsoredLink(string newNote);}
 
  contract EthereumWhite is ERC20 {                     
     using SafeMath for uint256;                        
     string public constant symbol = "EWHITE";          
     string public constant name = "Ethereum White";    
     uint8 public constant decimals = 8;                
     uint256 _totalSupply = 9000000 * (10**8);          
     uint256 public _maxtotalSupply = 90000000 * (10**8);   
     uint clock;                                        
     uint public clockairdrop;                          
     uint clockowner;                                   
     uint public clockpos;                              
     uint public clockmint;
     uint MultiReward;           
     uint MultiRewardAD;                       
     uint public Miners;                                
     uint public Airdrop;                               
     uint public PoS;
     uint public TotalAirdropRequests;                  
     uint public TotalPoSRequests;                      
     uint public  rewardAD;                             
     uint public _reward;                               
     uint public _rewardPoS;                            
     uint public MaxMinersXblock;                       
     uint public MaxAirDropXblock;                      
     uint public MaxPoSXblock;                          
     uint public constant InitalPos = 10000 * (10**8);  
     uint public gas;                                   
     uint public BlockMined;                            
     uint public PoSPerCent;                            
     uint public reqfee;
     struct transferInStruct{
     uint128 reward;
     uint64 time;  }
     address public owner;
     mapping(address => uint256) balances;
     mapping(address => mapping (address => uint256)) allowed;
     mapping(address => transferInStruct[]) transferIns;
 
function InitialSettings() onlyOwner returns (bool success) {
    MultiReward = 45;     
    MultiRewardAD = 45;
    PoSPerCent = 2000;
    Miners = 0;         
    Airdrop = 0;                        
    PoS = 0;
    MaxMinersXblock = 10;                   
    MaxAirDropXblock=5;            
    MaxPoSXblock=2;       
    clock = 1509269936;                                 
    clockairdrop = 1509269936;                         
    clockowner = 1509269936;                           
    clockpos = 1509269936;                             
    clockmint = 1509269936;
    reqfee = 1000000000;}
 
     modifier onlyPayloadSize(uint size) { 
        require(msg.data.length >= size + 4);
        _;}
 
    string public SponsoredLink = "Ethereum White";        
    function setSponsor(string note_) public onlyOwner {
      SponsoredLink = note_;
      SponsoredLink(SponsoredLink); }
 
    function ShowADV(){
       SponsoredLink(SponsoredLink);}
 
     function EthereumWhite() {
         owner = msg.sender;
         balances[owner] = 9000000 * (10**8);
         }
 
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;  }
 
     function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;      }
 
     function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];     }
 
        function SetMaxMinersXblock(uint _MaxMinersXblock) onlyOwner {
        MaxMinersXblock=  _MaxMinersXblock;   }
 
        function SetMaxAirDropXblock(uint _MaxAirDropXblock) onlyOwner {
        MaxAirDropXblock=  _MaxAirDropXblock;        }
 
        function SetMaxPosXblock(uint _MaxPoSXblock) onlyOwner {
         MaxPoSXblock=  _MaxPoSXblock;        }        
 
        function SetRewardMultiAD(uint _MultiRewardAD) onlyOwner {
         MultiRewardAD=  _MultiRewardAD;        }        
 
      function SetRewardMulti(uint _MultiReward) onlyOwner {
         MultiReward=  _MultiReward;        }        
  
        function SetGasFeeReimbursed(uint _Gasfee) onlyOwner{
         gas=  _Gasfee * 1 wei;}       
 
         function transfer(address _to, uint256 _amount)  onlyPayloadSize(2 * 32) returns (bool success){
         if (balances[msg.sender] >= _amount 
            && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             if(_totalSupply> _maxtotalSupply){
             gas = 0;
             }
                if (balances[msg.sender] >= reqfee){
             balances[msg.sender] -= _amount - gas ;}
             else{
            balances[msg.sender] -= _amount;}
             balances[_to] += _amount;
             Transfer(msg.sender, _to, _amount);
             _totalSupply = _totalSupply.add(tx.gasprice);
             ShowADV();
            return true;
             } else { throw;}}

 
     function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(2 * 32) returns (bool success) {
         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             ShowADV();
             return true;
         }   else {
             throw;} }
 
         modifier canMint() {
         uint _now = now;
        require(_totalSupply < _maxtotalSupply);
        require ((_now.sub(clockmint)).div(90 seconds) >= 1);
        _; }
 
        function Mine_Block() canMint returns (bool) {
         if(clockmint < clockowner) {return false;}
         if(Miners >= MaxMinersXblock){
         clockmint = now; 
         Miners=0;
         return true;}
         if(balances[msg.sender] <= (100 * (10**8))){ return false;}
         Miners++;
         uint Calcrewardminers =1000000*_maxtotalSupply.div(((_totalSupply/9)*10)+(TotalAirdropRequests));
         _reward = Calcrewardminers*MultiReward;  
         uint reward = _reward;
        _totalSupply = _totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        Mine(msg.sender, reward);
        BlockMined++;
        ShowADV();
        return true;}
 
        modifier canAirdrop() { 
         uint _now = now;
        require(_totalSupply < _maxtotalSupply);
        require ((_now.sub(clockairdrop)).div(60 seconds) >= 1);
        _;}
 
         function Request_Airdrop() canAirdrop returns (bool) {
         if(clockairdrop < clockowner){ return false;}
         if(Airdrop >= MaxAirDropXblock){
         clockairdrop = now; 
         Airdrop=0;
        return true; }
          if(balances[msg.sender] > (100 * (10**8))) return false;
         Airdrop++;
         uint Calcrewardairdrop =100000*_maxtotalSupply.div(((_totalSupply/9)*10)+TotalAirdropRequests);
         uint _reward = Calcrewardairdrop*MultiRewardAD;
         rewardAD = _reward;
        _totalSupply = _totalSupply.add(rewardAD);
        balances[msg.sender] = balances[msg.sender].add(rewardAD);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        MineAD(msg.sender, rewardAD);
        TotalAirdropRequests++;
        ShowADV();
        return true;}
 
        modifier canPoS() {
         uint _now = now;
        require(_totalSupply < _maxtotalSupply);
        require ((_now.sub(clockpos)).div(120 seconds) >= 1);
         uint _nownetowk = now;
        _;}
 
         function Proof_of_Stake() canPoS returns (bool) {
         if(clockpos < clockowner){return false;}
         if(PoS >= MaxPoSXblock){
         clockpos = now; 
         PoS=0;
         return true; }
         PoS++;
         if(balances[msg.sender] >= InitalPos){
         uint ProofOfStake = balances[msg.sender].div(PoSPerCent);
         _rewardPoS = ProofOfStake;                     
         uint rewardPoS = _rewardPoS;
        _totalSupply = _totalSupply.add(rewardPoS);
        balances[msg.sender] = balances[msg.sender].add(rewardPoS);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        MinePoS(msg.sender, rewardPoS);
        TotalPoSRequests++;
}else throw;
        ShowADV();
        return true;}
 
        function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
         return true;}
 
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];}}