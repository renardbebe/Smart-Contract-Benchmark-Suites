 

pragma solidity ^0.4.4;

 
contract Owned {
     
    address public owner;

     
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}

 
contract Destroyable {
    address public hammer;

     
    function setHammer(address _hammer) onlyHammer
    { hammer = _hammer; }

     
    function destroy() onlyHammer
    { suicide(msg.sender); }

     
    modifier onlyHammer { if (msg.sender != hammer) throw; _; }
}

 
contract Object is Owned, Destroyable {
    function Object() {
        owner  = msg.sender;
        hammer = msg.sender;
    }
}

 
 
contract ERC20 
{
 
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256);

 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Token is Object, ERC20 {
     
    string public name;
    string public symbol;

     
    uint public totalSupply;

     
    uint8 public decimals;
    
     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
 
     
    function balanceOf(address _owner) constant returns (uint256)
    { return balances[_owner]; }
 
     
    function allowance(address _owner, address _spender) constant returns (uint256)
    { return allowances[_owner][_spender]; }

     
    function Token(string _name, string _symbol, uint8 _decimals, uint _count) {
        name        = _name;
        symbol      = _symbol;
        decimals    = _decimals;
        totalSupply = _count;
        balances[msg.sender] = _count;
    }
 
     
    function transfer(address _to, uint _value) returns (bool) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to]        += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var avail = allowances[_from][msg.sender]
                  > balances[_from] ? balances[_from]
                                    : allowances[_from][msg.sender];
        if (avail >= _value) {
            allowances[_from][msg.sender] -= _value;
            balances[_from] -= _value;
            balances[_to]   += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {
        allowances[msg.sender][_spender] += _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function unapprove(address _spender)
    { allowances[msg.sender][_spender] = 0; }
}

contract TokenEmission is Token {
    function TokenEmission(string _name, string _symbol, uint8 _decimals,
                           uint _start_count)
             Token(_name, _symbol, _decimals, _start_count)
    {}

     
    function emission(uint _value) onlyOwner {
         
        if (_value + totalSupply < totalSupply) throw;

        totalSupply     += _value;
        balances[owner] += _value;
    }
 
     
    function burn(uint _value) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            totalSupply      -= _value;
        }
    }
}

 
contract Recipient {
     
    event ReceivedEther(address indexed sender,
                        uint256 indexed amount);

     
    event ReceivedTokens(address indexed from,
                         uint256 indexed value,
                         address indexed token,
                         bytes extraData);

     
    function receiveApproval(address _from, uint256 _value,
                             ERC20 _token, bytes _extraData) {
        if (!_token.transferFrom(_from, this, _value)) throw;
        ReceivedTokens(_from, _value, _token, _extraData);
    }

     
    function () payable
    { ReceivedEther(msg.sender, msg.value); }
}

 
contract Crowdfunding is Object, Recipient {
     
    address public fund;

     
    TokenEmission public bounty;
    
     
    mapping(address => uint256) public donations;

     
    uint256 public totalFunded;

     
    string public reference;

     
    Params public config;

    struct Params {
         
        uint256 startBlock;
        uint256 stopBlock;

         
        uint256 minValue;
        uint256 maxValue;
        
         
        uint256 bountyScale;
        uint256 startRatio;
        uint256 reductionStep;
        uint256 reductionValue;
    }

     
    function bountyValue(uint256 _value, uint256 _block) constant returns (uint256) {
        if (_block < config.startBlock || _block > config.stopBlock)
            return 0;

        var R = config.startRatio;
        var B = config.startBlock;
        var S = config.reductionStep;
        var V = config.reductionValue;
        uint256 ratio = R - (_block - B) / S * V; 
        return _value * ratio / config.bountyScale; 
    }

     
    modifier onlyRunning {
        bool isRunning = totalFunded  < config.maxValue
                      && block.number > config.startBlock
                      && block.number < config.stopBlock;
        if (!isRunning) throw;
        _;
    }

     
    modifier onlyFailure {
        bool isFailure = totalFunded  < config.minValue
                      && block.number > config.stopBlock;
        if (!isFailure) throw;
        _;
    }

     
    modifier onlySuccess {
        bool isSuccess = totalFunded >= config.minValue
                      && block.number > config.stopBlock;
        if (!isSuccess) throw;
        _;
    }

     
    function Crowdfunding(
        address _fund,
        address _bounty,
        string  _reference,
        uint256 _startBlock,
        uint256 _stopBlock,
        uint256 _minValue,
        uint256 _maxValue,
        uint256 _scale,
        uint256 _startRatio,
        uint256 _reductionStep,
        uint256 _reductionValue
    ) {
        fund      = _fund;
        bounty    = TokenEmission(_bounty);
        reference = _reference;

        config.startBlock     = _startBlock;
        config.stopBlock      = _stopBlock;
        config.minValue       = _minValue;
        config.maxValue       = _maxValue;
        config.bountyScale    = _scale;
        config.startRatio     = _startRatio;
        config.reductionStep  = _reductionStep;
        config.reductionValue = _reductionValue;
    }

     
    function () payable onlyRunning {
        ReceivedEther(msg.sender, msg.value);

        totalFunded           += msg.value;
        donations[msg.sender] += msg.value;

        var bountyVal = bountyValue(msg.value, block.number);
        bounty.emission(bountyVal);
        bounty.transfer(msg.sender, bountyVal);
    }

     
    function withdraw() onlySuccess
    { if (!fund.send(this.balance)) throw; }

     
    function refund() onlyFailure {
        var donation = donations[msg.sender];
        donations[msg.sender] = 0;
        if (!msg.sender.send(donation)) throw;
    }

     
    function receiveApproval(address _from, uint256 _value,
                             ERC20 _token, bytes _extraData)
    { throw; }
}

library CreatorCrowdfunding {
    function create(address _fund, address _bounty, string _reference, uint256 _startBlock, uint256 _stopBlock, uint256 _minValue, uint256 _maxValue, uint256 _scale, uint256 _startRatio, uint256 _reductionStep, uint256 _reductionValue) returns (Crowdfunding)
    { return new Crowdfunding(_fund, _bounty, _reference, _startBlock, _stopBlock, _minValue, _maxValue, _scale, _startRatio, _reductionStep, _reductionValue); }

    function version() constant returns (string)
    { return "v0.6.3"; }

    function abi() constant returns (string)
    { return '[{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"withdraw","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hammer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"refund","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"config","outputs":[{"name":"startBlock","type":"uint256"},{"name":"stopBlock","type":"uint256"},{"name":"minValue","type":"uint256"},{"name":"maxValue","type":"uint256"},{"name":"bountyScale","type":"uint256"},{"name":"startRatio","type":"uint256"},{"name":"reductionStep","type":"uint256"},{"name":"reductionValue","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"destroy","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_value","type":"uint256"},{"name":"_block","type":"uint256"}],"name":"bountyValue","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"},{"name":"_token","type":"address"},{"name":"_extraData","type":"bytes"}],"name":"receiveApproval","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"bounty","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalFunded","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"fund","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"reference","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"donations","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hammer","type":"address"}],"name":"setHammer","outputs":[],"payable":false,"type":"function"},{"inputs":[{"name":"_fund","type":"address"},{"name":"_bounty","type":"address"},{"name":"_reference","type":"string"},{"name":"_startBlock","type":"uint256"},{"name":"_stopBlock","type":"uint256"},{"name":"_minValue","type":"uint256"},{"name":"_maxValue","type":"uint256"},{"name":"_scale","type":"uint256"},{"name":"_startRatio","type":"uint256"},{"name":"_reductionStep","type":"uint256"},{"name":"_reductionValue","type":"uint256"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":true,"name":"amount","type":"uint256"}],"name":"ReceivedEther","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"value","type":"uint256"},{"indexed":true,"name":"token","type":"address"},{"indexed":false,"name":"extraData","type":"bytes"}],"name":"ReceivedTokens","type":"event"}]'; }
}

 
contract Builder is Object {
     
    event Builded(address indexed client, address indexed instance);
 
     
    mapping(address => address[]) public getContractsOf;
 
     
    function getLastContract() constant returns (address) {
        var sender_contracts = getContractsOf[msg.sender];
        return sender_contracts[sender_contracts.length - 1];
    }

     
    address public beneficiary;

     
    function setBeneficiary(address _beneficiary) onlyOwner
    { beneficiary = _beneficiary; }

     
    uint public buildingCostWei;

     
    function setCost(uint _buildingCostWei) onlyOwner
    { buildingCostWei = _buildingCostWei; }

     
    string public securityCheckURI;

     
    function setSecurityCheck(string _uri) onlyOwner
    { securityCheckURI = _uri; }
}

 
 
 
contract BuilderCrowdfunding is Builder {
     
    function create(
        address _fund,
        address _bounty,
        string _reference,
        uint256 _startBlock,
        uint256 _stopBlock,
        uint256 _minValue,
        uint256 _maxValue,
        uint256 _scale,
        uint256 _startRatio,
        uint256 _reductionStep,
        uint256 _reductionValue,
        address _client
    ) payable returns (address) {
        if (buildingCostWei > 0 && beneficiary != 0) {
             
            if (msg.value < buildingCostWei) throw;
             
            if (!beneficiary.send(buildingCostWei)) throw;
             
            if (msg.value > buildingCostWei) {
                if (!msg.sender.send(msg.value - buildingCostWei)) throw;
            }
        } else {
             
            if (msg.value > 0) {
                if (!msg.sender.send(msg.value)) throw;
            }
        }

        if (_client == 0)
            _client = msg.sender;
 
        var inst = CreatorCrowdfunding.create(_fund, _bounty, _reference, _startBlock,
                                              _stopBlock, _minValue, _maxValue, _scale,
                                              _startRatio, _reductionStep, _reductionValue);
        inst.setOwner(_client);
        inst.setHammer(_client);
        getContractsOf[_client].push(inst);
        Builded(_client, inst);
        return inst;
    }
}