 

pragma solidity 0.5.9;


 


 

 

 
 
 
 

 
 
 
 

 
 

library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

 

contract Medianizer {
    function peek() public view returns (bytes32, bool) {}
}

contract Dai {
     function transferFrom(address src, address dst, uint wad) public returns (bool) {}
}


 


 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


 
contract RektFyi is Ownable {

    using DSMath for uint;

     

    struct Receiver {
        uint walletBalance;
        uint bountyETH;
        uint bountyDAI;
        uint timestamp;
        uint etherPrice;
        address payable sender;
    }

    struct Vault {
        uint fee;
        uint bountyETH;
        uint bountySAI;  
        uint bountyDAI;  
    }

    struct Pot {
        uint ETH;
        uint DAI;
    }


    mapping(address => Receiver) public receiver;
    mapping(address => uint) public balance;
    mapping(address => address[]) private recipients;
    mapping(address => Pot) public unredeemedBounty;
    mapping(address => Vault) public vault;
    Pot public bountyPot = Pot(0,0);
    uint public feePot = 0;

    bool public shutdown = false;
    uint public totalSupply = 0;
    uint public multiplier = 1300000000000000000;  
    uint public bumpBasePrice = 10000000000000000;  
    uint public holdTimeCeiling = 3628800;  

    address public medianizerAddress;
    Medianizer oracle;

    bool public isMCD = false;
    uint public MCDswitchTimestamp = 0;
    address public saiAddress;
    address public daiAddress;

    Dai dai;
    Dai sai;


    constructor(address _medianizerAddress, address _saiAddress) public {
        medianizerAddress = _medianizerAddress;
        oracle = Medianizer(medianizerAddress);

        saiAddress = _saiAddress;
        dai = Dai(saiAddress);
        sai = dai;
    }


     

    string public constant name = "REKT.fyi";
    string public constant symbol = "REKT";
    uint8 public constant decimals = 0;

    uint public constant WAD = 1000000000000000000;
    uint public constant PRECISION = 100000000000000;  
    uint public constant MULTIPLIER_FLOOR = 1000000000000000000;  
    uint public constant MULTIPLIER_CEILING = 10000000000000000000;  
    uint public constant BONUS_FLOOR = 1250000000000000000;  
    uint public constant BONUS_CEILING = 1800000000000000000;  
    uint public constant BOUNTY_BONUS_MINIMUM = 5000000000000000000;  
    uint public constant HOLD_SCORE_CEILING = 1000000000000000000000000000;  
    uint public constant BUMP_INCREMENT = 100000000000000000;  
    uint public constant HOLD_TIME_MAX = 23670000;  
    uint public constant BUMP_PRICE_MAX = 100000000000000000;  


     

    event LogVaultDeposit(address indexed addr, string indexed potType, uint value);
    event LogWithdraw(address indexed to, uint eth, uint sai, uint dai);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event LogBump(uint indexed from, uint indexed to, uint cost, address indexed by);
    event LogBurn(
        address indexed sender,
        address indexed receiver,
        uint receivedAt,
        uint multiplier,
        uint initialETH,
        uint etherPrice,
        uint bountyETH,
        uint bountyDAI,
        uint reward
        );
    event LogGive(address indexed sender, address indexed receiver);


     

    modifier shutdownNotActive() {
        require(shutdown == false, "shutdown activated");
        _;
    }


    modifier giveRequirementsMet(address _to) {
        require(address(_to) != address(0), "Invalid address");
        require(_to != msg.sender, "Cannot give to yourself");
        require(balanceOf(_to) == 0, "Receiver already has a token");
        require(_to.balance > 0, "Receiver wallet must not be empty");
        _;
    }


     

     
     
    function give(address _to) external payable shutdownNotActive giveRequirementsMet(_to) {
        if (msg.value > 0) {
            unredeemedBounty[msg.sender].ETH = unredeemedBounty[msg.sender].ETH.add(msg.value);
            bountyPot.ETH = bountyPot.ETH.add(msg.value);
        }
        receiver[_to] = Receiver(_to.balance, msg.value, 0, now, getPrice(), msg.sender);
        giveCommon(_to);
    }


     
     
     
    function giveWithDAI(address _to, uint _amount) external shutdownNotActive giveRequirementsMet(_to) {
        if (_amount > 0) {
             
             
             
            require(MCDswitchTimestamp != now, "Cannot send DAI during the switching block");
            require(dai.transferFrom(msg.sender, address(this), _amount), "DAI transfer failed");
            unredeemedBounty[msg.sender].DAI = unredeemedBounty[msg.sender].DAI.add(_amount);
            bountyPot.DAI = bountyPot.DAI.add(_amount);
        }
        receiver[_to] = Receiver(_to.balance, 0, _amount, now, getPrice(), msg.sender);
        giveCommon(_to);
    }


     
     
     
     
    function bump(bool _up) external payable shutdownNotActive {
        require(msg.value > 0, "Ether required");
        uint initialMultiplier = multiplier;

         
        uint bumpAmount = msg.value
            .wdiv(bumpBasePrice)
            .wmul(getBonusMultiplier(msg.sender))
            .wmul(BUMP_INCREMENT);

        if (_up) {
            if (multiplier.add(bumpAmount) >= MULTIPLIER_CEILING) {
                multiplier = MULTIPLIER_CEILING;
            } else {
                multiplier = multiplier.add(roundBumpAmount(bumpAmount));
            }
        }
        else {
            if (multiplier > bumpAmount) {
                if (multiplier.sub(bumpAmount) <= MULTIPLIER_FLOOR) {
                    multiplier = MULTIPLIER_FLOOR;
                } else {
                    multiplier = multiplier.sub(roundBumpAmount(bumpAmount));
                }
            }
            else {
                multiplier = MULTIPLIER_FLOOR;
            }
        }

        emit LogBump(initialMultiplier, multiplier, msg.value, msg.sender);
        feePot = feePot.add(msg.value);
    }


     
     
     
     
    function burn(address _receiver) external {
        require(balanceOf(_receiver) == 1, "Nothing to burn");
        address sender = receiver[_receiver].sender;
        require(
            msg.sender == _receiver ||
            msg.sender == sender ||
            (_receiver == address(this) && msg.sender == owner),
            "Must be token sender or receiver, or must be the owner burning REKT sent to the contract"
            );

        if (!shutdown) {
            if (receiver[_receiver].walletBalance.wmul(multiplier) > _receiver.balance) {
                uint balanceValueThen = receiver[_receiver].walletBalance.wmul(receiver[_receiver].etherPrice);
                uint balanceValueNow = _receiver.balance.wmul(getPrice());
                if (balanceValueThen.wmul(multiplier) > balanceValueNow) {
                    revert("Not enough gains");
                }
            }
        }

        balance[_receiver] = 0;
        totalSupply --;
        
        emit Transfer(_receiver, address(0), 1);

        uint feeReward = distributeBurnRewards(_receiver, sender);

        emit LogBurn(
            sender,
            _receiver,
            receiver[_receiver].timestamp,
            multiplier,
            receiver[_receiver].walletBalance,
            receiver[_receiver].etherPrice,
            receiver[_receiver].bountyETH,
            receiver[_receiver].bountyDAI,
            feeReward);
    }


     
     
    function withdraw(address payable _addr) external {
        require(_addr != address(this), "This contract cannot withdraw to itself");
        withdrawCommon(_addr, _addr);
    }


     
     
     
    function withdrawSelf(address payable _destination) external onlyOwner {
        withdrawCommon(_destination, address(this));
    }


     
     
    function setNewMedianizer(address _addr) external onlyOwner {
        require(address(_addr) != address(0), "Invalid address");
        medianizerAddress = _addr;
        oracle = Medianizer(medianizerAddress);
        bytes32 price;
        bool ok;
        (price, ok) = oracle.peek();
        require(ok, "Pricefeed error");
    }


     
     
     
     
     
     
     
     
     
     
    function setMCD(address _addr) external onlyOwner {
        require(!isMCD, "MCD has already been set");
        require(address(_addr) != address(0), "Invalid address");
        daiAddress = _addr;
        dai = Dai(daiAddress);
        isMCD = true;
        MCDswitchTimestamp = now;
    }


     
     
    function setBumpPrice(uint _amount) external onlyOwner {
        require(_amount > 0 && _amount <= BUMP_PRICE_MAX, "Price must not be higher than BUMP_PRICE_MAX");
        bumpBasePrice = _amount;
    }


     
     
    function setHoldTimeCeiling(uint _seconds) external onlyOwner {
        require(_seconds > 0 && _seconds <= HOLD_TIME_MAX, "Hold time must not be higher than HOLD_TIME_MAX");
        holdTimeCeiling = _seconds;
    }
    

     
     
    function setShutdown() external onlyOwner {
        shutdown = true;
    }


     

     
     
     
     
    function calculateBountyProportion(uint _bounty) public view returns (uint) {
        return _bounty.rdiv(potValue(bountyPot.DAI, bountyPot.ETH));
    }


     
     
     
    function calculateHoldScore(uint _receivedAtTime) public view returns (uint) {
        if (now == _receivedAtTime)
        {
            return 0;
        }
        uint timeDiff = now.sub(_receivedAtTime);
        uint holdScore = timeDiff.rdiv(holdTimeCeiling);
        if (holdScore > HOLD_SCORE_CEILING) {
            holdScore = HOLD_SCORE_CEILING;
        }
        return holdScore;
    }


     
     
     
     
    function balanceOf(address _receiver) public view returns (uint) {
        return balance[_receiver];
    }


     
     
     
     
     
    function potValue(uint _dai, uint _eth) public view returns (uint) {
        return _dai.add(_eth.wmul(getPrice()));
    }


     
     
     
    function getBonusMultiplier(address _sender) public view returns (uint) {
        uint bounty = potValue(unredeemedBounty[_sender].DAI, unredeemedBounty[_sender].ETH);
        uint bonus = WAD;
        if (bounty >= BOUNTY_BONUS_MINIMUM) {
            bonus = bounty.wdiv(potValue(bountyPot.DAI, bountyPot.ETH)).add(BONUS_FLOOR);
            if (bonus > BONUS_CEILING) {
                bonus = BONUS_CEILING;
            }
        }
        return bonus;
    }


     
     
     
    function getRecipients(address _sender) public view returns (address[] memory) {
        return recipients[_sender];
    }


     
     
    function getPrice() public view returns (uint) {
        bytes32 price;
        bool ok;
        (price, ok) = oracle.peek();
        require(ok, "Pricefeed error");
        return uint(price);
    }


     

     
     
    function giveCommon(address _to) private {
        balance[_to] = 1;
        recipients[msg.sender].push(_to);
        totalSupply ++;
        emit Transfer(address(0), msg.sender, 1);
        emit Transfer(msg.sender, _to, 1);
        emit LogGive(msg.sender, _to);
    }


     
     
     
     
     
    function distributeBurnRewards(address _receiver, address _sender) private returns (uint feeReward) {

        feeReward = 0;

        uint bountyETH = receiver[_receiver].bountyETH;
        uint bountyDAI = receiver[_receiver].bountyDAI;
        uint bountyTotal = potValue(bountyDAI, bountyETH);

        if (bountyTotal > 0 ) {
            uint bountyProportion = calculateBountyProportion(bountyTotal);
            uint userRewardPot = bountyProportion.rmul(feePot);

            if (shutdown) {
                 
                feeReward = userRewardPot;
            } else {
                uint holdScore = calculateHoldScore(receiver[_receiver].timestamp);
                feeReward = userRewardPot.rmul(holdScore);
            }

            if (bountyETH > 0) {
                 
                unredeemedBounty[_sender].ETH = unredeemedBounty[_sender].ETH.sub(bountyETH);
                bountyPot.ETH = bountyPot.ETH.sub(bountyETH);

                 
                vault[_receiver].bountyETH = vault[_receiver].bountyETH.add(bountyETH);
                emit LogVaultDeposit(_receiver, 'bountyETH', bountyETH);

            } else if (bountyDAI > 0) {
                unredeemedBounty[_sender].DAI = unredeemedBounty[_sender].DAI.sub(bountyDAI);
                bountyPot.DAI = bountyPot.DAI.sub(bountyDAI);
                if (isMCD && receiver[_receiver].timestamp > MCDswitchTimestamp) {
                    vault[_receiver].bountyDAI = vault[_receiver].bountyDAI.add(bountyDAI);
                } else {  
                    vault[_receiver].bountySAI = vault[_receiver].bountySAI.add(bountyDAI);
                }
                emit LogVaultDeposit(_receiver, 'bountyDAI', bountyDAI);
            }

            if (feeReward > 0) {
                feeReward = feeReward / 2;

                 
                feePot = feePot.sub(feeReward);
                vault[_receiver].fee = vault[_receiver].fee.add(feeReward);
                emit LogVaultDeposit(_receiver, 'reward', feeReward);

                 
                feePot = feePot.sub(feeReward);
                vault[_sender].fee = vault[_sender].fee.add(feeReward);
                emit LogVaultDeposit(_sender, 'reward', feeReward);
            }
        }

        return feeReward;
    }


     
     
     
    function roundBumpAmount(uint _amount) private pure returns (uint rounded) {
        require(_amount >= PRECISION, "bump size too small to round");
        return (_amount / PRECISION).mul(PRECISION);
    }


     
     
     
     
     
    function withdrawCommon(address payable _destination, address _vaultOwner) private {
        require(address(_destination) != address(0), "Invalid address");
        uint amountETH = vault[_vaultOwner].fee.add(vault[_vaultOwner].bountyETH);
        uint amountDAI = vault[_vaultOwner].bountyDAI;
        uint amountSAI = vault[_vaultOwner].bountySAI;
        vault[_vaultOwner] = Vault(0,0,0,0);
        emit LogWithdraw(_destination, amountETH, amountSAI, amountDAI);
        if (amountDAI > 0) {
            require(dai.transferFrom(address(this), _destination, amountDAI), "DAI transfer failed");
        }
        if (amountSAI > 0) {
            require(sai.transferFrom(address(this), _destination, amountSAI), "SAI transfer failed");
        }
        if (amountETH > 0) {
            _destination.transfer(amountETH);
        }
    }
}