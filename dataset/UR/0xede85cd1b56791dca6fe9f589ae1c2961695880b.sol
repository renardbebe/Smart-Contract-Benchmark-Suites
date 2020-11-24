 

 
pragma solidity ^0.4.18;

contract BinksBucksToken {
     
    string public constant name = "Binks Bucks";
    string public constant symbol = "BINX";
    uint8 public constant decimals = 18;
    uint internal _totalSupply = 0;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping (address => uint256)) _allowed;

    function totalSupply() public constant returns (uint) {
         
        return _totalSupply;
    }

    function balanceOf(address owner) public constant returns (uint) {
         
        return _balances[owner];
    }

     
    function hasAtLeast(address adr, uint amount) constant internal returns (bool) {
        if (amount <= 0) {return false;}
        return _balances[adr] >= amount;
    }

    function canRecieve(address adr, uint amount) constant internal returns (bool) {
        if (amount <= 0) {return false;}
        uint balance = _balances[adr];
        return (balance + amount > balance);
    }

    function hasAllowance(address proxy, address spender, uint amount) constant internal returns (bool) {
        if (amount <= 0) {return false;}
        return _allowed[spender][proxy] >= amount;
    }

    function canAdd(uint x, uint y) pure internal returns (bool) {
        uint total = x + y;
        if (total > x && total > y) {return true;}
        return false;
    }

     

    function transfer(address to, uint amount) public returns (bool) {
         
        require(canRecieve(to, amount));
        require(hasAtLeast(msg.sender, amount));
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        Transfer(msg.sender, to, amount);
        return true;
    }

   function allowance(address proxy, address spender) public constant returns (uint) {
        
        return _allowed[proxy][spender];
    }

    function approve(address spender, uint amount) public returns (bool) {
         
        _allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
         
        require(hasAllowance(msg.sender, from, amount));
        require(canRecieve(to, amount));
        require(hasAtLeast(from, amount));
        _allowed[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        Transfer(from, to, amount);
        return true;
    }

    event Transfer(address indexed, address indexed, uint);
    event Approval(address indexed proxy, address indexed spender, uint amount);
}

contract Giveaway is BinksBucksToken {
     
    address internal giveaway_master;
    address internal imperator;
    uint32 internal _code = 0;
    uint internal _distribution_size = 1000000000000000000000;
    uint internal _max_distributions = 100;
    uint internal _distributions_left = 100;
    uint internal _distribution_number = 0;
    mapping(address => uint256) internal _last_distribution;

    function transferAdmin(address newImperator) public {
            require(msg.sender == imperator);
            imperator = newImperator;
        }

    function transferGiveaway(address newaddress) public {
        require(msg.sender == imperator || msg.sender == giveaway_master);
        giveaway_master = newaddress;
    }

    function startGiveaway(uint32 code, uint max_distributions) public {
         
        require(msg.sender == imperator || msg.sender == giveaway_master);
        _code = code;
        _max_distributions = max_distributions;
        _distributions_left = max_distributions;
        _distribution_number += 1;
    }

    function setDistributionSize(uint num) public {
         
        require(msg.sender == imperator || msg.sender == giveaway_master);
        _code = 0;
        _distribution_size = num;
    }

    function CodeEligible() public view returns (bool) {
         
        return (_code != 0 && _distributions_left > 0 && _distribution_number > _last_distribution[msg.sender]);
    }

    function EnterCode(uint32 code) public {
         
        require(CodeEligible());
        if (code == _code) {
            _last_distribution[msg.sender] = _distribution_number;
            _distributions_left -= 1;
            require(canRecieve(msg.sender, _distribution_size));
            require(hasAtLeast(this, _distribution_size));
            _balances[this] -= _distribution_size;
            _balances[msg.sender] += _distribution_size;
            Transfer(this, msg.sender, _distribution_size);
        }
    }
}

contract BinksBucks is BinksBucksToken, Giveaway {
     
    function BinksBucks(address bossman) public {
        imperator = msg.sender;
        giveaway_master = bossman;
         
        _balances[this] += 240000000000000000000000000;
        _totalSupply += 240000000000000000000000000;
         
        _balances[bossman] += 750000000000000000000000000;
        _totalSupply += 750000000000000000000000000;
         
        _balances[msg.sender] += 10000000000000000000000000;
        _totalSupply += 10000000000000000000000000;
    }
}