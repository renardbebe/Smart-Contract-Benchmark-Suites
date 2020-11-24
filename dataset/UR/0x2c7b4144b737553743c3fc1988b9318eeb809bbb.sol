 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
 
 interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
 
 
 contract Token is ERC20 {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    constructor(string memory _tokenName, string memory _tokenSymbol,uint256 _initialSupply,uint8 _decimals) public {
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        name = _tokenName;
        symbol = _tokenSymbol;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}

contract ethGame{
    using SafeMath for uint256;
    
    Token GainToken;  
    
    uint256 private _stageSn = 60;  
    uint256 private _stage = 1;  
    uint256 private _stageToken = 0;  
    uint256 private _totalCoin = 0;  
    uint256 private _totalGain = 0;  
    
    
    address private owner;
    
    mapping (address => uint256) private _balances;
    
    event Exchange(address _from, uint256 value);
    
    constructor(address GainAddress,uint256 StageSn) public {
        GainToken = Token(GainAddress);  
        _stageSn = StageSn;
        
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setOwner(address _owner) public onlyOwner returns(bool) {
        owner = _owner;
        return true;
    }
    
    function withdraw(uint256 value) public onlyOwner returns(bool){
        (msg.sender).transfer(value);
        return true;
    }
    
    function exchange() public payable returns (bool){
         
        require(msg.value >= 1000000000000000,'value minimum');

         
        uint256 gain = getGain(msg.value);
        GainToken.transferFrom(address(owner),msg.sender,gain);
        
         
        _totalGain = _totalGain.add(gain);
        
         
        _totalCoin = _totalCoin.add(msg.value);
        
         
        _balances[msg.sender] = _balances[msg.sender].add(gain);
         
        
        emit Exchange(msg.sender, gain);
        return true;
    }
    
    function getGain(uint256 value) private returns (uint256){  
        uint256 sn = getStageTotal(_stage);
        uint256 rate = sn.div(_stageSn);   
        
        uint256 gain = 0;
        
         
        uint256 TmpGain = rate.mul(value).div(10**18); 
        
         
        uint256 TmpStageToken = _stageToken.mul(1000).add(TmpGain);  
        
         
        if(sn < TmpStageToken){
             
            uint256 TmpStageTotal = _stageToken.mul(1000);
             
            uint256 TmpGainAdd = sn.sub(TmpStageTotal);  
            gain = gain.add(TmpGainAdd.div(10**3));  
            
             
            _stage = _stage.add(1);
            _stageToken = 0;
            
            uint256 LowerSn = getStageTotal(_stage);
            
            uint256 LowerRate = LowerSn.div(_stageSn);
            
             
            uint256 LastRate = LowerRate.mul(10**10).div(rate);
            uint256 LowerGain = (TmpGain - TmpGainAdd).mul(LastRate);
            
             
            require(LowerSn >= LowerGain.div(10**10),'exceed max');
            
             
            _stageToken = _stageToken.add(LowerGain.div(10**13));
            
            gain = gain.add(LowerGain.div(10**13));  
            
            return gain;
        }else{
             
            gain = value.mul(rate);
            
             
            _stageToken = _stageToken.add(gain.div(10**21));
            
            return gain.div(10**21);  
        }
    }
    
    function setStage(uint256 n) public onlyOwner returns (bool){
        _stage = n;
        return true;
    }
    
    function setStageToken(uint256 value) public onlyOwner returns (bool){
        _stageToken = value;
        return true;
    }
    
    function getStageTotal(uint256 n) public pure returns (uint256) {
        require(n>=1);
        require(n<=1000);
        uint256 a = 1400000 * 14400 - 16801 * n ** 2;
        uint256 b = (250000 - (n - 499) ** 2) * 22 * 1440;
        uint256 c = 108722 * 1000000;
        uint256 d = 14400 * 100000;
        uint256 sn = (a - b) * c / d;
        return sn;  
    }
    
    function getAttr() public view returns (uint256[4] memory){
        uint256[4] memory attr = [_stage,_stageToken,_totalCoin,_totalGain];
        return attr;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    
}