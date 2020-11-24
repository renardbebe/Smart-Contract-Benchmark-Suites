 

pragma solidity ^0.4.19;

contract BaseToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        Transfer(_from, _to, _value);
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

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract AirdropToken is BaseToken {
    uint256 public airAmount;
    uint256 public airBegintime;
    uint256 public airEndtime;
    address public airSender;
    uint32 public airLimitCount;

    mapping (address => uint32) public airCountOf;

    event Airdrop(address indexed from, uint32 indexed count, uint256 tokenValue);

    function airdrop() public payable {
        require(now >= airBegintime && now <= airEndtime);
        require(msg.value == 0);
        if (airLimitCount > 0 && airCountOf[msg.sender] >= airLimitCount) {
            revert();
        }
        _transfer(airSender, msg.sender, airAmount);
        airCountOf[msg.sender] += 1;
        Airdrop(msg.sender, airCountOf[msg.sender], airAmount);
    }
}

contract ICOToken is BaseToken {
     
    uint256 public icoRatio;
    uint256 public icoBegintime;
    uint256 public icoEndtime;
    address public icoSender;
    address public icoHolder;

    event ICO(address indexed from, uint256 indexed value, uint256 tokenValue);
    event Withdraw(address indexed from, address indexed holder, uint256 value);

    function ico() public payable {
        require(now >= icoBegintime && now <= icoEndtime);
        uint256 tokenValue = (msg.value * icoRatio * 10 ** uint256(decimals)) / (1 ether / 1 wei);
        if (tokenValue == 0 || balanceOf[icoSender] < tokenValue) {
            revert();
        }
        _transfer(icoSender, msg.sender, tokenValue);
        ICO(msg.sender, msg.value, tokenValue);
    }

    function withdraw() public {
        uint256 balance = this.balance;
        icoHolder.transfer(balance);
        Withdraw(msg.sender, icoHolder, balance);
    }
}

contract CustomToken is BaseToken, AirdropToken, ICOToken {
    function CustomToken() public {
        totalSupply = 21000000000000000000000000000;
        name = 'FundofFunds';
        symbol = 'FOF';
        decimals = 18;
        balanceOf[0xfb3eb237657ed64ec8ae40da2a02e3dbaab2505f] = totalSupply;
        Transfer(address(0), 0xfb3eb237657ed64ec8ae40da2a02e3dbaab2505f, totalSupply);

        airAmount = 20000000000000000000;
        airBegintime = 1522029600;
        airEndtime = 1585188000;
        airSender = 0xfb3eb237657ed64ec8ae40da2a02e3dbaab2505f;
        airLimitCount = 0;

        icoRatio = 3000;
        icoBegintime = 1522036800;
        icoEndtime = 1837656000;
        icoSender = 0xfb3eb237657ed64ec8ae40da2a02e3dbaab2505f;
        icoHolder = 0xfb3eb237657ed64ec8ae40da2a02e3dbaab2505f;
    }

    function() public payable {
        if (msg.value == 0) {
            airdrop();
        } else {
            ico();
        }
    }
}