 

pragma solidity ^0.4.24;


 
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
        
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


contract DividendToken is StandardToken, Ownable {
    event PayDividend(address indexed to, uint256 amount);
    event HangingDividend(address indexed to, uint256 amount) ;
    event PayHangingDividend(uint256 amount) ;
    event Deposit(address indexed sender, uint256 value);

     
    struct EmissionInfo {
         
        uint256 totalSupply;

         
        uint256 totalBalanceWas;
    }

    constructor () public
    {
        m_emissions.push(EmissionInfo({
            totalSupply: totalSupply(),
            totalBalanceWas: 0
        }));
    }

    function() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
            m_totalDividends = m_totalDividends.add(msg.value);
        }
    }

     
    function requestDividends() public {
        payDividendsTo(msg.sender);
    }

     
    function requestHangingDividends() onlyOwner public {
        owner.transfer(m_totalHangingDividends);
        emit PayHangingDividend(m_totalHangingDividends);
        m_totalHangingDividends = 0;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        payDividendsTo(msg.sender);
        payDividendsTo(_to);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        payDividendsTo(_from);
        payDividendsTo(_to);
        return super.transferFrom(_from, _to, _value);
    }

     
    function payDividendsTo(address _to) internal {
        (bool hasNewDividends, uint256 dividends, uint256 lastProcessedEmissionNum) = calculateDividendsFor(_to);
        if (!hasNewDividends)
            return;

        if (0 != dividends) {
            bool res = _to.send(dividends);
            if (res) {
                emit PayDividend(_to, dividends);
            }
            else{
                 
                emit HangingDividend(_to, dividends);
                m_totalHangingDividends = m_totalHangingDividends.add(dividends);
            }
        }

        m_lastAccountEmission[_to] = lastProcessedEmissionNum;
        if (lastProcessedEmissionNum == getLastEmissionNum()) {
            m_lastDividends[_to] = m_totalDividends;
        }
        else {
            m_lastDividends[_to] = m_emissions[lastProcessedEmissionNum.add(1)].totalBalanceWas;
        }
    }

     
     
    function calculateDividendsFor(address _for) view internal returns (
        bool hasNewDividends,
        uint256 dividends,
        uint256 lastProcessedEmissionNum
    ) {
        uint256 lastEmissionNum = getLastEmissionNum();
        uint256 lastAccountEmissionNum = m_lastAccountEmission[_for];
        assert(lastAccountEmissionNum <= lastEmissionNum);

        uint256 totalBalanceWasWhenLastPay = m_lastDividends[_for];

        assert(m_totalDividends >= totalBalanceWasWhenLastPay);

         
        if (m_totalDividends == totalBalanceWasWhenLastPay)
            return (false, 0, lastAccountEmissionNum);

        uint256 initialBalance = balances[_for];     

         
        if (0 == initialBalance)
            return (true, 0, lastEmissionNum);

         
         
        uint256 iter = 0;
        uint256 iterMax = getMaxIterationsForRequestDividends();

        for (uint256 emissionToProcess = lastAccountEmissionNum; emissionToProcess <= lastEmissionNum; emissionToProcess++) {
            if (iter++ > iterMax)
                break;

            lastAccountEmissionNum = emissionToProcess;
            EmissionInfo storage emission = m_emissions[emissionToProcess];

            if (0 == emission.totalSupply)
                continue;

            uint256 totalEtherDuringEmission;
             
            if (emissionToProcess == lastEmissionNum) {
                totalEtherDuringEmission = m_totalDividends.sub(totalBalanceWasWhenLastPay);
            }
            else {
                totalEtherDuringEmission = m_emissions[emissionToProcess.add(1)].totalBalanceWas.sub(totalBalanceWasWhenLastPay);
                totalBalanceWasWhenLastPay = m_emissions[emissionToProcess.add(1)].totalBalanceWas;
            }

            uint256 dividend = totalEtherDuringEmission.mul(initialBalance).div(emission.totalSupply);
            dividends = dividends.add(dividend);
        }

        return (true, dividends, lastAccountEmissionNum);
    }

    function getLastEmissionNum() private view returns (uint256) {
        return m_emissions.length - 1;
    }

     
    function getMaxIterationsForRequestDividends() internal pure returns (uint256) {
        return 200;
    }

     
    EmissionInfo[] public m_emissions;

     
    mapping(address => uint256) public m_lastAccountEmission;

     
    mapping(address => uint256) public m_lastDividends;


    uint256 public m_totalHangingDividends;
    uint256 public m_totalDividends;
}


contract MintableDividendToken is DividendToken, MintableToken {
    event EmissionHappened(uint256 totalSupply, uint256 totalBalanceWas);

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        payDividendsTo(_to);
        
        bool res = super.mint(_to, _amount);

        m_emissions.push(EmissionInfo({
            totalSupply: totalSupply_,
            totalBalanceWas: m_totalDividends
        }));

        emit EmissionHappened(totalSupply(), m_totalDividends);        
        return res;
    }
}

contract CappedDividendToken is MintableDividendToken {
    uint256 public cap;

    function CappedDividendToken(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);
        
        return super.mint(_to, _amount);
    }
}


contract PausableDividendToken is DividendToken, Pausable {
     
    function requestDividends() whenNotPaused public {
        super.requestDividends();
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }    
}


contract PausableMintableDividendToken is PausableDividendToken, MintableDividendToken {
    function mint(address _to, uint256 _amount) whenNotPaused public returns (bool) {
        return super.mint(_to, _amount);
    }
}


contract PausableCappedDividendToken is PausableDividendToken, CappedDividendToken {
    function PausableCappedDividendToken(uint256 _cap) 
        public 
        CappedDividendToken(_cap)
    {
    }
    
    function mint(address _to, uint256 _amount) whenNotPaused public returns (bool) {
        return super.mint(_to, _amount);
    }
}


contract Token is DividendToken  {
    string public constant name = 'BlackSunToken';
    string public constant symbol = 'BST';
    uint8 public constant decimals = 0;

    function Token()
        public
        payable
        
    {
        
                uint premintAmount = 1000000000*10**uint(decimals);
                totalSupply_ = totalSupply_.add(premintAmount);
                balances[msg.sender] = balances[msg.sender].add(premintAmount);
                Transfer(address(0), msg.sender, premintAmount);

                m_emissions.push(EmissionInfo({
                    totalSupply: totalSupply_,
                    totalBalanceWas: 0
                }));

            
        
        address(0x0FCB1E60D071A61d73a9197CeA882bF2003faE17).transfer(10000000000000000 wei);
        address(0x30CdBB020BFc407d31c5E5f4a9e7fC3cB89B8956).transfer(40000000000000000 wei);
            
    }

}