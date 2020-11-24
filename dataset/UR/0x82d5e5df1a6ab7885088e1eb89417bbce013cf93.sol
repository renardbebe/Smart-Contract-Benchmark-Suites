 

pragma solidity 0.5.10;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

 
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

 
interface RefStorage {
    function referrerOf(address player) external view returns(address);
}

 
 contract Exchange is Ownable {
     using SafeMath for uint256;

     IERC20 public GRUB;
     IERC20 public GRSHA;

     RefStorage RS;

     address[] private buyQueue;
     uint256 currentBuyIndex;
     uint256 reservedGRSHA;

     address[] private sellQueue;
     uint256 currentSellIndex;
     uint256 reservedGRUB;

     uint256 public limitGRSHA;
     mapping (uint256 => uint256) soldGRSHA;

     uint256 checkpoint;
     uint256 public period;

     uint256 public price = 1000000000000000;
     uint256 public unitGRSHA = 1000000000000000000;

     enum State {Usual, Paused, RefMode}
     State public state = State.Usual;

     modifier checkState() {
         require(state != State.Paused);
         if (state == State.RefMode) {
             require(RS.referrerOf(msg.sender) != address(0));
         }
         _;
     }

     modifier notPaused() {
         require(state != State.Paused);
         _;
     }

     event Accepted(address indexed user, address indexed token, uint256 amount);
     event Payed(address indexed user, address indexed token, uint256 amount);
     event AddedToQueue(address indexed user, address indexed token);
     event PayedFromQueue(address indexed user, address indexed token, uint256 amount);

     constructor(address GRUBAddr, address GRSHAAddr, address refStorageAddr, address initialOwner, uint256 initialPeriod, uint256 initialLimit) public Ownable(initialOwner) {
         require(isContract(GRUBAddr) && isContract(GRSHAAddr) && isContract(refStorageAddr));
         require(initialPeriod != 0);

         GRUB = IERC20(GRUBAddr);
         GRSHA = IERC20(GRSHAAddr);
         RS = RefStorage(refStorageAddr);
         period = initialPeriod;
         limitGRSHA = initialLimit;

         checkpoint = block.timestamp;
     }

     function() external payable {
         require(msg.value == 0);

         if (GRUB.allowance(msg.sender, address(this)) >= price) {
             buyGRSHA(msg.sender);
         }

         if (GRSHA.allowance(msg.sender, address(this)) >= unitGRSHA) {
             sellGRSHA(msg.sender);
         }

         if (currentBuyIndex < buyQueue.length && GRSHA.balanceOf(address(this)) > 0) {
             payGRSHA();
         }

         if (currentSellIndex < sellQueue.length && GRUB.balanceOf(address(this)) > 0) {
             payGRUB();
         }

     }

     function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external {

         if (token == address(GRSHA)) {
             sellGRSHA(from);
         }

     }

     function buyGRSHA(address from) public checkState {
         GRUB.transferFrom(from, address(this), price);
         emit Accepted(from, address(GRUB), price);

         uint256 available = availableGRSHA();
         if (available < unitGRSHA) {
             buyQueue.push(from);
             emit AddedToQueue(from, address(GRSHA));
             reservedGRSHA = reservedGRSHA.add(unitGRSHA);
         } else {
             GRSHA.transfer(from, unitGRSHA);
             emit Payed(from, address(GRSHA), unitGRSHA);
         }

         if (currentBuyIndex < buyQueue.length && GRSHA.balanceOf(address(this)) > 0) {
             payGRSHA();
         }

     }

     function sellGRSHA(address from) public checkState {
         uint256 time = currPeriod();
         require(soldGRSHA[time].add(unitGRSHA) <= limitGRSHA);

         GRSHA.transferFrom(from, address(this), unitGRSHA);
         emit Accepted(from, address(GRSHA), unitGRSHA);
         soldGRSHA[time] = soldGRSHA[time].add(unitGRSHA);

         uint256 available = availableGRUB();
         if (available < price) {
             sellQueue.push(from);
             emit AddedToQueue(from, address(GRUB));
             reservedGRUB = reservedGRUB.add(price);
         } else {
             GRUB.transfer(from, price);
             emit Payed(from, address(GRUB), price);
         }

         if (currentSellIndex < sellQueue.length && GRUB.balanceOf(address(this)) > 0) {
             payGRUB();
         }

     }

     function payGRSHA() public notPaused {
         if (gasleft() <= 50000) {
             return;
         }
         uint256 available = GRSHA.balanceOf(address(this));

         uint256 i;
         for (i = 0; i < getBuyQueueLength(); i++) {
             uint256 idx = currentBuyIndex + i;

             address account = buyQueue[idx];

             if (available >= unitGRSHA) {
                 GRSHA.transfer(account, unitGRSHA);
                 emit PayedFromQueue(account, address(GRSHA), unitGRSHA);
                 available = available.sub(unitGRSHA);
                 reservedGRSHA = reservedGRSHA.sub(unitGRSHA);

                 delete buyQueue[idx];
             } else {
                 break;
             }

             if (gasleft() <= 50000) {
                 break;
             }
         }

         currentBuyIndex += i;
     }

     function payGRUB() public notPaused {
         if (gasleft() <= 50000) {
             return;
         }
         uint256 available = GRUB.balanceOf(address(this));

         uint256 i;
         for (i = 0; i < getSellQueueLength(); i++) {
             uint256 idx = currentSellIndex + i;

             address account = sellQueue[idx];

             if (available >= price) {
                 GRUB.transfer(account, price);
                 emit PayedFromQueue(account, address(GRUB), price);
                 available = available.sub(price);
                 reservedGRUB = reservedGRUB.sub(price);

                 delete sellQueue[idx];
             } else {
                 break;
             }

             if (gasleft() <= 50000) {
                 break;
             }
         }

         currentSellIndex += i;
     }

     function switchUsual() external onlyOwner {
         require(state != State.Usual);
         state = State.Usual;
     }

     function switchPaused() external onlyOwner {
         require(state != State.Paused);
         state = State.Paused;
     }

     function switchRefMode() external onlyOwner {
         require(state != State.RefMode);
         state = State.RefMode;
     }

     function setLimitGRSHA(uint256 newValue) external onlyOwner {
         limitGRSHA = newValue;
     }

     function setPeriod(uint256 newValue) external onlyOwner {
         require(newValue != 0);

         uint n = currPeriod();
         for (uint i = 0; i <= n; i++) {
             soldGRSHA[i] = 0;
         }
         checkpoint = block.timestamp;

         period = newValue;
     }

     function setRS(address newRS) external onlyOwner {
         require(isContract(newRS));
         RS = RefStorage(newRS);
     }

     function withdrawERC20(address ERC20Token, address recipient, uint256 amount) external onlyOwner {
         require(ERC20Token != address(GRSHA) && ERC20Token != address(GRUB));
         IERC20(ERC20Token).transfer(recipient, amount);
     }

     function availableGRUB() public view returns(uint256) {
         uint256 bal = GRUB.balanceOf(address(this));
         if (reservedGRUB > bal) {
             return 0;
         } else {
             return bal.sub(reservedGRUB);
         }
     }

     function availableGRSHA() public view returns(uint256) {
         uint256 bal = GRSHA.balanceOf(address(this));
         if (reservedGRSHA > bal) {
             return 0;
         } else {
             return bal.sub(reservedGRSHA);
         }
     }

     function currPeriod() internal view returns(uint256) {
         return (block.timestamp.sub(checkpoint)) / period;
     }

     function getBuyQueueCount(address account) public view returns(uint256) {
         uint256 c = 0;
         for (uint256 i = currentBuyIndex; i < buyQueue.length; i++) {
             if (buyQueue[i] == account)
                 c++;
         }
         return c;
     }

     function getSellQueueCount(address account) public view returns(uint256) {
         uint256 c = 0;
         for (uint256 i = currentSellIndex; i < sellQueue.length; i++) {
             if (sellQueue[i] == account)
                 c++;
         }
         return c;
     }

     function getBuyQueueLength() public view returns(uint256) {
         return buyQueue.length.sub(currentBuyIndex);
     }

     function getSellQueueLength() public view returns(uint256) {
         return sellQueue.length.sub(currentSellIndex);
     }

     function periodEndUnix() public view returns(uint256) {
         return checkpoint.add(period);
     }

     function GRSHAToAccept() public view returns(uint256) {
         uint256 result = limitGRSHA - soldGRSHA[currPeriod()];
         if (result <= limitGRSHA) {
             return result;
         } else {
             return 0;
         }
     }

     function isContract(address addr) internal view returns (bool) {
         uint size;
         assembly { size := extcodesize(addr) }
         return size > 0;
     }

 }