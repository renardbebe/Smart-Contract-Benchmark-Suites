 

 

pragma solidity ^0.4.21;

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract DET is EIP20Interface {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
     
    address public god;
     
    mapping (address => uint256) public balances;
     
    mapping (address => mapping (address => uint256)) public allowed;

     
    struct ServiceStat {
        address user;
        uint64 serviceId;
        string serviceName;
        uint256 timestamp; 
    }

     
    mapping (address => mapping (uint64 => ServiceStat)) public serviceStatMap;

     
    struct ServiceConfig{
        uint64 serviceId;
        string serviceName;
        uint256 price;
        uint256 discount;
        address fitAddr;
        string detail;
    }
     
    mapping (uint64 => ServiceConfig) public serviceConfgMap;
    mapping (uint64 => uint256) public serviceWin;
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
     
    uint256 public tokenPrice;
    
     
    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        god = msg.sender;
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function getMsgSender() public view returns(address sender){
        return msg.sender;
    }

     
    function setConfig(uint64 _serviceId, string _serviceName, uint256 _price, uint256 _discount, address _fitAddr, string _desc) public returns (bool success){
        require(msg.sender==god);
        serviceConfgMap[_serviceId].serviceId = _serviceId;
        serviceConfgMap[_serviceId].serviceName = _serviceName;
        serviceConfgMap[_serviceId].price = _price;
        serviceConfgMap[_serviceId].discount = _discount;
        serviceConfgMap[_serviceId].fitAddr = _fitAddr;
        serviceConfgMap[_serviceId].detail = _desc;
        return true;
    }

     
    function configOf(uint64 _serviceId) public view returns (string serviceName, uint256 price, uint256 discount, address addr, string desc){
        serviceName = serviceConfgMap[_serviceId].serviceName;
        price = serviceConfgMap[_serviceId].price;
        discount = serviceConfgMap[_serviceId].discount;
        addr = serviceConfgMap[_serviceId].fitAddr;
        desc = serviceConfgMap[_serviceId].detail;
    }

     
    function buyService(uint64 _serviceId,uint64 _count) public returns (uint256 cost, uint256 timestamp){
        require(_count >= 1);
         
         
        cost = serviceConfgMap[_serviceId].price * serviceConfgMap[_serviceId].discount * _count / 100;
        address fitAddr = serviceConfgMap[_serviceId].fitAddr;
         
        if( transfer(fitAddr,cost ) == true ){
            uint256 timeEx = serviceStatMap[msg.sender][_serviceId].timestamp;
            if(timeEx == 0){
                serviceStatMap[msg.sender][_serviceId].serviceId = _serviceId;
                serviceStatMap[msg.sender][_serviceId].serviceName = serviceConfgMap[_serviceId].serviceName;
                serviceStatMap[msg.sender][_serviceId].user = msg.sender;
                serviceStatMap[msg.sender][_serviceId].timestamp = now + (_count * 86400);
                serviceWin[_serviceId] += cost;
                timestamp = serviceStatMap[msg.sender][_serviceId].timestamp;
            }else{
                if(timeEx < now){
                    timeEx = now;
                }
                timeEx += (_count * 86400);
                serviceStatMap[msg.sender][_serviceId].timestamp = timeEx;
                timestamp = timeEx;
            }
        }else{
            timestamp = 0;
        }
        
    }

     
    function buyServiceByAdmin(uint64 _serviceId,uint64 _count,address addr) public returns (uint256 cost, uint256 timestamp){
        require(msg.sender==god);
        require(_count >= 1);
         
         
        cost = serviceConfgMap[_serviceId].price * serviceConfgMap[_serviceId].discount * _count / 100;
        address fitAddr = serviceConfgMap[_serviceId].fitAddr;
        timestamp = 0;
        require(balances[addr] >= cost);
        balances[fitAddr] += cost;
        balances[addr] -= cost;
        emit Transfer(addr, fitAddr, cost); 

        uint256 timeEx = serviceStatMap[addr][_serviceId].timestamp;
        if(timeEx == 0){
            serviceStatMap[addr][_serviceId].serviceId = _serviceId;
            serviceStatMap[addr][_serviceId].serviceName = serviceConfgMap[_serviceId].serviceName;
            serviceStatMap[addr][_serviceId].user = addr;
            serviceStatMap[addr][_serviceId].timestamp = now + (_count * 86400); 
            serviceWin[_serviceId] += cost;
            timestamp = serviceStatMap[addr][_serviceId].timestamp;
        }else{
            if(timeEx < now){
                timeEx = now;
            }
            timeEx += (_count * 86400);
            serviceStatMap[addr][_serviceId].timestamp = timeEx;
            timestamp = timeEx;
        }    
    }

     
    function getServiceStat(uint64 _serviceId) public view returns (uint256 timestamp){
        timestamp = serviceStatMap[msg.sender][_serviceId].timestamp;
    }
    
     
    function getServiceStatByAddr(uint64 _serviceId,address addr) public view returns (uint256 timestamp){
        require(msg.sender==god);
        timestamp = serviceStatMap[addr][_serviceId].timestamp;
    }

     
    function getWin(uint64 _serviceId) public view returns (uint256 win){
        require(msg.sender==god);
        win = serviceWin[_serviceId];
        return win;
    }
     
    function setPrice(uint256 _price) public returns (bool success){
        require(msg.sender==god);
        tokenPrice = _price;
        return true;
    }

     
    function getPrice() public view returns (uint256 _price){
        require(msg.sender==god);
        _price = tokenPrice;
        return tokenPrice;
    }
}