 

pragma solidity ^0.4.11;


contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
}

 
 
 
 

 
 
 

 
 
 

 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
        emit Approval(msg.sender, _spender, _value);
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

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}

contract Erc20Dist is SafeMath {
    TokenERC20  public  _erc20token;  

    address public _ownerDist; 
    uint256 public _distDay; 
    uint256 public _mode = 0; 
    uint256 public _lockAllAmount; 

    struct Detail{ 
        address founder; 
        uint256 lockDay; 
        uint256 lockPercent; 
        uint256 distAmount; 
        uint256 lockAmount; 
        uint256 initAmount; 
        uint256 distRate; 
        uint256 oneDayTransferAmount; 
        uint256 transferedAmount; 
        uint256 lastTransferDay; 
        bool isFinish; 
        bool isCancelDist; 
    }
    Detail private detail = Detail(address(0),0,0,0,0,0,0,0,0,0, false, false); 
    Detail[] public _details; 
	uint256 public _detailsLength = 0; 

    bool public _fDist = false; 
    bool public _fConfig = false; 
    bool public _fFinish = false; 
    bool public _fCancelDist = false; 
    
    function Erc20Dist() public {
        _ownerDist = msg.sender;  
    }

    function () public{} 

     
    function setOwner(address owner_) public {
        require (msg.sender == _ownerDist, "you must _ownerDist"); 
        require(_fDist == false, "not dist");  
        require(_fConfig == false, "not config"); 
        _ownerDist = owner_;
    }
     
    function setErc20(TokenERC20  erc20Token) public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(address(_erc20token) == address(0),"you have set erc20Token"); 
        require(erc20Token.balanceOf(address(this)) > 0, "this contract must own tokens");
        _erc20token = erc20Token; 
        _lockAllAmount = erc20Token.balanceOf(address(this));
    }

     
    function cancelDist() public {
        require(_fDist == true, "must dist");  
        require(_fCancelDist == false, "must not cancel dist");

         
        for(uint256 i=0;i<_details.length;i++){
             
            if ( _details[i].founder == msg.sender ) {
                 
                _details[i].isCancelDist = true;
                break;
            }
        }
         
        updateCancelDistFlag();
        if (_fCancelDist == true) {
            require(_erc20token.balanceOf(address(this)) > 0, "must have balance");
             
            _erc20token.transfer(
                _ownerDist, 
                _erc20token.balanceOf(address(this))
            );
        }
    }

     
    function updateCancelDistFlag() private {
        bool allCancelDist = true;
        for(uint256 i=0; i<_details.length; i++){
             
            if (_details[i].isCancelDist == false) {
                allCancelDist = false;
                break;
            }
        }
         
        _fCancelDist = allCancelDist;
    }

     
    function clearConfig() public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(_fDist == false, "not dist");  
        require(address(_erc20token) != address(0),"you must set erc20Token"); 
        require(_erc20token.balanceOf(address(this)) > 0, "must have balance");
         
        _erc20token.transfer(
            msg.sender, 
            _erc20token.balanceOf(address(this))
        );
         
        _lockAllAmount = 0;
        TokenERC20  nullErc20token;
        _erc20token = nullErc20token;
        Detail[] nullDetails;
        _details = nullDetails;
        _detailsLength = 0;
        _mode = 0;
        _fConfig = false;
    }

     
    function withDraw() public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(_fFinish == true, "dist must be finished");  
        require(address(_erc20token) != address(0),"you must set erc20Token"); 
        require(_erc20token.balanceOf(address(this)) > 0, "must have balance");
         
        _erc20token.transfer(
            _ownerDist, 
            _erc20token.balanceOf(address(this))
        );
    }

     
    function configContract(uint256 mode,address[] founders,uint256[] distWad18Amounts,uint256[] lockPercents,uint256[] lockDays,uint256[] distRates) public {
     
     
     
     
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(mode==1||mode==2,"there is only mode 1 or 2"); 
        _mode = mode; 
        require(_fConfig == false,"you have configured it already"); 
        require(address(_erc20token) != address(0), "you must setErc20 first"); 
        require(founders.length!=0,"array length can not be zero"); 
        require(founders.length==distWad18Amounts.length,"founders length dismatch distWad18Amounts length"); 
        require(distWad18Amounts.length==lockPercents.length,"distWad18Amounts length dismatch lockPercents length"); 
        require(lockPercents.length==lockDays.length,"lockPercents length dismatch lockDays length"); 
        require(lockDays.length==distRates.length,"lockDays length dismatch distRates length"); 

         
        for(uint256 i=0;i<founders.length;i++){
            require(distWad18Amounts[i]!=0,"dist token amount can not be zero"); 
            for(uint256 j=0;j<i;j++){
                require(founders[i]!=founders[j],"you could not give the same address of founders"); 
            }
        }
        

         
        uint256 totalAmount = 0; 
        uint256 distAmount = 0; 
        uint256 oneDayTransferAmount = 0; 
        uint256 lockAmount = 0; 
        uint256 initAmount = 0; 

         
        for(uint256 k=0;k<lockPercents.length;k++){
            require(lockPercents[k]<=100,"lockPercents unit must <= 100"); 
            require(distRates[k]<=10000,"distRates unit must <= 10000"); 
            distAmount = mul(distWad18Amounts[k],10**18); 
            totalAmount = add(totalAmount,distAmount); 
            lockAmount = div(mul(lockPercents[k],distAmount),100); 
            initAmount = sub(distAmount, lockAmount); 
            oneDayTransferAmount = div(mul(distRates[k],lockAmount),10000); 

             
            detail.founder = founders[k];
            detail.lockDay = lockDays[k];
            detail.lockPercent = lockPercents[k];
            detail.distRate = distRates[k];
            detail.distAmount = distAmount;
            detail.lockAmount = lockAmount;
            detail.initAmount = initAmount;
            detail.oneDayTransferAmount = oneDayTransferAmount;
            detail.transferedAmount = 0; 
            detail.lastTransferDay = 0; 
            detail.isFinish = false;
            detail.isCancelDist = false;
             
            _details.push(detail);
        }
        require(totalAmount <= _lockAllAmount, "distributed total amount should be equal lock amount"); 
        require(totalAmount <= _erc20token.totalSupply(),"distributed total amount should be less than token totalSupply"); 
		_detailsLength = _details.length;
        _fConfig = true; 
        _fFinish = false; 
        _fCancelDist = false; 
    }

     
    function startDistribute() public {
        require (msg.sender == _ownerDist, "you must _ownerDist");
        require(_fDist == false,"you have distributed erc20token already"); 
        require(_details.length != 0,"you have not configured"); 
        _distDay = today(); 
        uint256 initDistAmount=0; 

        for(uint256 i=0;i<_details.length;i++){
            initDistAmount = _details[i].initAmount; 

            if(_details[i].lockDay==0){ 
                initDistAmount = add(initDistAmount, _details[i].oneDayTransferAmount); 
            }
            _erc20token.transfer(
                _details[i].founder,
               initDistAmount
            );
            _details[i].transferedAmount = initDistAmount; 
            _details[i].lastTransferDay =_distDay; 
        }

        _fDist = true; 
        updateFinishFlag(); 
    }

     
    function updateFinishFlag() private {
         
        bool allFinish = true;
        for(uint256 i=0; i<_details.length; i++){
             
            if (_details[i].lockPercent == 0) {
                _details[i].isFinish = true;
                continue;
            }
             
            if (_details[i].distAmount == _details[i].transferedAmount) {
                _details[i].isFinish = true;
                continue;
            }
            allFinish = false;
        }
         
        _fFinish = allFinish;
    }

     
    function applyForTokenOneDay() public{
        require(_mode == 1,"this function can be called only when _mode==1"); 
        require(_distDay != 0,"you haven't distributed"); 
        require(_fFinish == false, "not finish"); 
        require(_fCancelDist == false, "must not cancel dist");
        uint256 daysAfterDist; 
        uint256 tday = today(); 
      
        for(uint256 i=0;i<_details.length;i++){
             
            if (_details[i].isFinish == true) {
                continue;
            }

            require(tday!=_details[i].lastTransferDay,"you have applied for todays token"); 
            daysAfterDist = sub(tday,_distDay); 
            if(daysAfterDist >= _details[i].lockDay){ 
                if(add(_details[i].transferedAmount, _details[i].oneDayTransferAmount) <= _details[i].distAmount){
                 
                    _erc20token.transfer(
                        _details[i].founder,
                        _details[i].oneDayTransferAmount
                    );
                     
                    _details[i].transferedAmount = add(_details[i].transferedAmount, _details[i].oneDayTransferAmount);
                }
                else if(_details[i].transferedAmount < _details[i].distAmount){
                 
                    _erc20token.transfer(
                        _details[i].founder,
                        sub( _details[i].distAmount, _details[i].transferedAmount)
                    );
                     
                    _details[i].transferedAmount = _details[i].distAmount;
                }
                 
                _details[i].lastTransferDay = tday;
            }
        }   
         
        updateFinishFlag();
    }

     
    function applyForToken() public {
        require(_mode == 2,"this function can be called only when _mode==2"); 
        require(_distDay != 0,"you haven't distributed"); 
        require(_fFinish == false, "not finish"); 
        require(_fCancelDist == false, "must not cancel dist");
        uint256 daysAfterDist; 
        uint256 expectAmount; 
        uint256 tday = today(); 
        uint256 expectReleaseTimesNoLimit = 0; 

        for(uint256 i=0;i<_details.length;i++){
             
            if (_details[i].isFinish == true) {
                continue;
            }
             
            require(tday!=_details[i].lastTransferDay,"you have applied for todays token");
            daysAfterDist = sub(tday,_distDay); 
            if(daysAfterDist >= _details[i].lockDay){ 
                expectReleaseTimesNoLimit = add(sub(daysAfterDist,_details[i].lockDay),1); 
                 
                 
                expectAmount = min(add(mul(expectReleaseTimesNoLimit,_details[i].oneDayTransferAmount),_details[i].initAmount),_details[i].distAmount);

                 
                _erc20token.transfer(
                    _details[i].founder,
                    sub(expectAmount, _details[i].transferedAmount)
                );
                 
                _details[i].transferedAmount = expectAmount;
                 
                _details[i].lastTransferDay = tday;
            }
        }
         
        updateFinishFlag();
    }

     
    function today() public constant returns (uint256) {
        return div(time(), 24 hours); 
    }
    
     
    function time() public constant returns (uint256) {
        return block.timestamp;
    }
 
}