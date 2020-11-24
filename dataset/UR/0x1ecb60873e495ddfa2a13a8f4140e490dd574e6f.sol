 

pragma solidity 0.4.24;

 

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
        bytes memory tempBytes;

        assembly {
             
             
            tempBytes := mload(0x40)

             
             
            let length := mload(_preBytes)
            mstore(tempBytes, length)

             
             
             
            let mc := add(tempBytes, 0x20)
             
             
            let end := add(mc, length)

            for {
                 
                 
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                 
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                 
                 
                mstore(mc, mload(cc))
            }

             
             
             
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

             
             
            mc := end
             
             
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

             
             
             
             
             
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)  
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
             
             
             
            let fslot := sload(_preBytes_slot)
             
             
             
             
             
             
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
             
             
             
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                 
                 
                 
                sstore(
                    _preBytes_slot,
                     
                     
                    add(
                         
                         
                        fslot,
                        add(
                            mul(
                                div(
                                     
                                    mload(add(_postBytes, 0x20)),
                                     
                                    exp(0x100, sub(32, mlength))
                                ),
                                 
                                 
                                exp(0x100, sub(32, newlength))
                            ),
                             
                             
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                 
                 
                 
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                 
                 
                 
                 
                 
                 

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                 
                mstore(0x0, _preBytes_slot)
                 
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))
                
                for { 
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                 
                 
                tempBytes := mload(0x40)

                 
                 
                 
                 
                 
                 
                 
                 
                let lengthmod := and(_length, 31)

                 
                 
                 
                 
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                     
                     
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                 
                 
                mstore(0x40, and(add(mc, 31), not(31)))
            }
             
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

             
            switch eq(length, mload(_postBytes))
            case 1 {
                 
                 
                 
                 
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                 
                 
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                     
                    if iszero(eq(mload(mc), mload(cc))) {
                         
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
             
            let fslot := sload(_preBytes_slot)
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

             
            switch eq(slength, mlength)
            case 1 {
                 
                 
                 
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                         
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                             
                            success := 0
                        }
                    }
                    default {
                         
                         
                         
                         
                        let cb := 1

                         
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                         
                         
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                 
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }
}

 

 
 
pragma solidity 0.4.24;

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
pragma solidity 0.4.24;



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 

 



pragma solidity 0.4.24;

contract HumanStandardToken is StandardToken {

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
library SafeMath {
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
}

 

 
contract MintAndBurnToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

 

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    constructor(
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = SafeMath.add(_amount, totalSupply);
    balances[_to] = SafeMath.add(_amount,balances[_to]);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

   
   
   
   

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) onlyOwner public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = SafeMath.sub(balances[_who],_value);
    totalSupply = SafeMath.sub(totalSupply,_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

contract SpankBank {
    using BytesLib for bytes;
    using SafeMath for uint256;

    event SpankBankCreated(
        uint256 periodLength,
        uint256 maxPeriods,
        address spankAddress,
        uint256 initialBootySupply,
        string bootyTokenName,
        uint8 bootyDecimalUnits,
        string bootySymbol
    );

    event StakeEvent(
        address staker,
        uint256 period,
        uint256 spankPoints,
        uint256 spankAmount,
        uint256 stakePeriods,
        address delegateKey,
        address bootyBase
    );

    event SendFeesEvent (
        address sender,
        uint256 bootyAmount
    );

    event MintBootyEvent (
        uint256 targetBootySupply,
        uint256 totalBootySupply
    );

    event CheckInEvent (
        address staker,
        uint256 period,
        uint256 spankPoints,
        uint256 stakerEndingPeriod
    );

    event ClaimBootyEvent (
        address staker,
        uint256 period,
        uint256 bootyOwed
    );

    event WithdrawStakeEvent (
        address staker,
        uint256 totalSpankToWithdraw
    );

    event SplitStakeEvent (
        address staker,
        address newAddress,
        address newDelegateKey,
        address newBootyBase,
        uint256 spankAmount
    );

    event VoteToCloseEvent (
        address staker,
        uint256 period
    );

    event UpdateDelegateKeyEvent (
        address staker,
        address newDelegateKey
    );

    event UpdateBootyBaseEvent (
        address staker,
        address newBootyBase
    );

    event ReceiveApprovalEvent (
        address from,
        address tokenContract
    );

     
     
    uint256 public periodLength;  
    uint256 public maxPeriods;  
    uint256 public totalSpankStaked;  
    bool public isClosed;  

     
     
    HumanStandardToken public spankToken;
    MintAndBurnToken public bootyToken;

     
     
     
     
     
    mapping(uint256 => uint256) public pointsTable;

     
    uint256 public currentPeriod = 0;

    struct Staker {
        uint256 spankStaked;  
        uint256 startingPeriod;  
        uint256 endingPeriod;  
        mapping(uint256 => uint256) spankPoints;  
        mapping(uint256 => bool) didClaimBooty;  
        mapping(uint256 => bool) votedToClose;  
        address delegateKey;  
        address bootyBase;  
    }

    mapping(address => Staker) public stakers;

    struct Period {
        uint256 bootyFees;  
        uint256 totalSpankPoints;  
        uint256 bootyMinted;  
        bool mintingComplete;  
        uint256 startTime;  
        uint256 endTime;  
        uint256 closingVotes;  
    }

    mapping(uint256 => Period) public periods;

    mapping(address => address) public stakerByDelegateKey;

    modifier SpankBankIsOpen() {
        require(isClosed == false);
        _;
    }

    constructor (
        uint256 _periodLength,
        uint256 _maxPeriods,
        address spankAddress,
        uint256 initialBootySupply,
        string bootyTokenName,
        uint8 bootyDecimalUnits,
        string bootySymbol
    )   public {
        periodLength = _periodLength;
        maxPeriods = _maxPeriods;
        spankToken = HumanStandardToken(spankAddress);
        bootyToken = new MintAndBurnToken(bootyTokenName, bootyDecimalUnits, bootySymbol);
        bootyToken.mint(this, initialBootySupply);

        uint256 startTime = now;

        periods[currentPeriod].startTime = startTime;
        periods[currentPeriod].endTime = SafeMath.add(startTime, periodLength);

        bootyToken.transfer(msg.sender, initialBootySupply);

         
        pointsTable[0] = 0;
        pointsTable[1] = 45;
        pointsTable[2] = 50;
        pointsTable[3] = 55;
        pointsTable[4] = 60;
        pointsTable[5] = 65;
        pointsTable[6] = 70;
        pointsTable[7] = 75;
        pointsTable[8] = 80;
        pointsTable[9] = 85;
        pointsTable[10] = 90;
        pointsTable[11] = 95;
        pointsTable[12] = 100;

        emit SpankBankCreated(_periodLength, _maxPeriods, spankAddress, initialBootySupply, bootyTokenName, bootyDecimalUnits, bootySymbol);
    }

     
    function stake(uint256 spankAmount, uint256 stakePeriods, address delegateKey, address bootyBase) SpankBankIsOpen public {
        doStake(msg.sender, spankAmount, stakePeriods, delegateKey, bootyBase);
    }

    function doStake(address stakerAddress, uint256 spankAmount, uint256 stakePeriods, address delegateKey, address bootyBase) internal {
        updatePeriod();
        require(stakePeriods > 0 && stakePeriods <= maxPeriods, "stake not between zero and maxPeriods");  
        require(spankAmount > 0, "stake is 0");  

         
        require(stakers[stakerAddress].startingPeriod == 0, "staker already exists");

         
        require(spankToken.transferFrom(stakerAddress, this, spankAmount));

        stakers[stakerAddress] = Staker(spankAmount, currentPeriod + 1, currentPeriod + stakePeriods, delegateKey, bootyBase);

        _updateNextPeriodPoints(stakerAddress, stakePeriods);

        totalSpankStaked = SafeMath.add(totalSpankStaked, spankAmount);

        require(delegateKey != address(0), "delegateKey does not exist");
        require(bootyBase != address(0), "bootyBase does not exist");
        require(stakerByDelegateKey[delegateKey] == address(0), "delegateKey already used");
        stakerByDelegateKey[delegateKey] = stakerAddress;

        emit StakeEvent(
            stakerAddress,
            currentPeriod + 1,
            stakers[stakerAddress].spankPoints[currentPeriod + 1],
            spankAmount,
            stakePeriods,
            delegateKey,
            bootyBase
        );
    }

     
     
    function _updateNextPeriodPoints(address stakerAddress, uint256 stakingPeriods) internal {
        Staker storage staker = stakers[stakerAddress];

        uint256 stakerPoints = SafeMath.div(SafeMath.mul(staker.spankStaked, pointsTable[stakingPeriods]), 100);

         
        uint256 totalPoints = periods[currentPeriod + 1].totalSpankPoints;
        totalPoints = SafeMath.add(totalPoints, stakerPoints);
        periods[currentPeriod + 1].totalSpankPoints = totalPoints;

        staker.spankPoints[currentPeriod + 1] = stakerPoints;
    }

    function receiveApproval(address from, uint256 amount, address tokenContract, bytes extraData) SpankBankIsOpen public returns (bool success) {
        require(msg.sender == address(spankToken), "invalid receiveApproval caller");

        address delegateKeyFromBytes = extraData.toAddress(12);
        address bootyBaseFromBytes = extraData.toAddress(44);
        uint256 periodFromBytes = extraData.toUint(64);

        emit ReceiveApprovalEvent(from, tokenContract);

        doStake(from, amount, periodFromBytes, delegateKeyFromBytes, bootyBaseFromBytes);
        return true;
    }

    function sendFees(uint256 bootyAmount) SpankBankIsOpen public {
        updatePeriod();

        require(bootyAmount > 0, "fee is zero");  
        require(bootyToken.transferFrom(msg.sender, this, bootyAmount));

        bootyToken.burn(bootyAmount);

        uint256 currentBootyFees = periods[currentPeriod].bootyFees;
        currentBootyFees = SafeMath.add(bootyAmount, currentBootyFees);
        periods[currentPeriod].bootyFees = currentBootyFees;

        emit SendFeesEvent(msg.sender, bootyAmount);
    }

    function mintBooty() SpankBankIsOpen public {
        updatePeriod();

         
        require(currentPeriod > 0, "current period is zero");

        Period storage period = periods[currentPeriod - 1];
        require(!period.mintingComplete, "minting already complete");  

        period.mintingComplete = true;

        uint256 targetBootySupply = SafeMath.mul(period.bootyFees, 20);
        uint256 totalBootySupply = bootyToken.totalSupply();

        if (targetBootySupply > totalBootySupply) {
            uint256 bootyMinted = targetBootySupply - totalBootySupply;
            bootyToken.mint(this, bootyMinted);
            period.bootyMinted = bootyMinted;
            emit MintBootyEvent(targetBootySupply, totalBootySupply);
        }
    }

     
     
     
     

    function updatePeriod() public {
        while (now >= periods[currentPeriod].endTime) {
            Period memory prevPeriod = periods[currentPeriod];
            currentPeriod += 1;
            periods[currentPeriod].startTime = prevPeriod.endTime;
            periods[currentPeriod].endTime = SafeMath.add(prevPeriod.endTime, periodLength);
        }
    }

     
     
    function checkIn(uint256 updatedEndingPeriod) SpankBankIsOpen public {
        updatePeriod();

        address stakerAddress =  stakerByDelegateKey[msg.sender];

        Staker storage staker = stakers[stakerAddress];

        require(staker.spankStaked > 0, "staker stake is zero");
        require(currentPeriod < staker.endingPeriod, "staker expired");
        require(staker.spankPoints[currentPeriod+1] == 0, "staker has points for next period");

         
        if (updatedEndingPeriod > 0) {
            require(updatedEndingPeriod > staker.endingPeriod, "updatedEndingPeriod less than or equal to staker endingPeriod");
            require(updatedEndingPeriod <= currentPeriod + maxPeriods, "updatedEndingPeriod greater than currentPeriod and maxPeriods");
            staker.endingPeriod = updatedEndingPeriod;
        }

        uint256 stakePeriods = staker.endingPeriod - currentPeriod;

        _updateNextPeriodPoints(stakerAddress, stakePeriods);

        emit CheckInEvent(stakerAddress, currentPeriod + 1, staker.spankPoints[currentPeriod + 1], staker.endingPeriod);
    }

    function claimBooty(uint256 claimPeriod) public {
        updatePeriod();

        Period memory period = periods[claimPeriod];
        require(period.mintingComplete, "booty not minted");

        address stakerAddress = stakerByDelegateKey[msg.sender];

        Staker storage staker = stakers[stakerAddress];

        require(!staker.didClaimBooty[claimPeriod], "staker already claimed");  

        uint256 stakerSpankPoints = staker.spankPoints[claimPeriod];
        require(stakerSpankPoints > 0, "staker has no points");  

        staker.didClaimBooty[claimPeriod] = true;

        uint256 bootyMinted = period.bootyMinted;
        uint256 totalSpankPoints = period.totalSpankPoints;

        uint256 bootyOwed = SafeMath.div(SafeMath.mul(stakerSpankPoints, bootyMinted), totalSpankPoints);

        require(bootyToken.transfer(staker.bootyBase, bootyOwed));

        emit ClaimBootyEvent(stakerAddress, claimPeriod, bootyOwed);
    }

    function withdrawStake() public {
        updatePeriod();

        Staker storage staker = stakers[msg.sender];
        require(staker.spankStaked > 0, "staker has no stake");

        require(isClosed || currentPeriod > staker.endingPeriod, "currentPeriod less than endingPeriod or spankbank closed");

        uint256 spankToWithdraw = staker.spankStaked;

        totalSpankStaked = SafeMath.sub(totalSpankStaked, staker.spankStaked);
        staker.spankStaked = 0;

        spankToken.transfer(msg.sender, spankToWithdraw);

        emit WithdrawStakeEvent(msg.sender, spankToWithdraw);
    }

    function splitStake(address newAddress, address newDelegateKey, address newBootyBase, uint256 spankAmount) public {
        updatePeriod();

        require(newAddress != address(0), "newAddress is zero");
        require(newDelegateKey != address(0), "delegateKey is zero");
        require(newBootyBase != address(0), "bootyBase is zero");
        require(stakerByDelegateKey[newDelegateKey] == address(0), "delegateKey in use");
        require(stakers[newAddress].startingPeriod == 0, "staker already exists");
        require(spankAmount > 0, "spankAmount is zero");

        Staker storage staker = stakers[msg.sender];
        require(currentPeriod < staker.endingPeriod, "staker expired");
        require(spankAmount <= staker.spankStaked, "spankAmount greater than stake");
        require(staker.spankPoints[currentPeriod+1] == 0, "staker has points for next period");

        staker.spankStaked = SafeMath.sub(staker.spankStaked, spankAmount);

        stakers[newAddress] = Staker(spankAmount, staker.startingPeriod, staker.endingPeriod, newDelegateKey, newBootyBase);

        stakerByDelegateKey[newDelegateKey] = newAddress;

        emit SplitStakeEvent(msg.sender, newAddress, newDelegateKey, newBootyBase, spankAmount);
    }

    function voteToClose() public {
        updatePeriod();

        Staker storage staker = stakers[msg.sender];

        require(staker.spankStaked > 0, "stake is zero");
        require(currentPeriod < staker.endingPeriod , "staker expired");
        require(staker.votedToClose[currentPeriod] == false, "stake already voted");
        require(isClosed == false, "SpankBank already closed");

        uint256 closingVotes = periods[currentPeriod].closingVotes;
        closingVotes = SafeMath.add(closingVotes, staker.spankStaked);
        periods[currentPeriod].closingVotes = closingVotes;

        staker.votedToClose[currentPeriod] = true;

        uint256 closingTrigger = SafeMath.div(totalSpankStaked, 2);
        if (closingVotes > closingTrigger) {
            isClosed = true;
        }

        emit VoteToCloseEvent(msg.sender, currentPeriod);
    }

    function updateDelegateKey(address newDelegateKey) public {
        require(newDelegateKey != address(0), "delegateKey is zero");
        require(stakerByDelegateKey[newDelegateKey] == address(0), "delegateKey already exists");

        Staker storage staker = stakers[msg.sender];
        require(staker.startingPeriod > 0, "staker starting period is zero");

        stakerByDelegateKey[staker.delegateKey] = address(0);
        staker.delegateKey = newDelegateKey;
        stakerByDelegateKey[newDelegateKey] = msg.sender;

        emit UpdateDelegateKeyEvent(msg.sender, newDelegateKey);
    }

    function updateBootyBase(address newBootyBase) public {
        Staker storage staker = stakers[msg.sender];
        require(staker.startingPeriod > 0, "staker starting period is zero");

        staker.bootyBase = newBootyBase;

        emit UpdateBootyBaseEvent(msg.sender, newBootyBase);
    }

    function getSpankPoints(address stakerAddress, uint256 period) public view returns (uint256)  {
        return stakers[stakerAddress].spankPoints[period];
    }

    function getDidClaimBooty(address stakerAddress, uint256 period) public view returns (bool)  {
        return stakers[stakerAddress].didClaimBooty[period];
    }

    function getVote(address stakerAddress, uint period) public view returns (bool) {
        return stakers[stakerAddress].votedToClose[period];
    }

    function getStakerFromDelegateKey(address delegateAddress) public view returns (address) {
        return stakerByDelegateKey[delegateAddress];
    }
}