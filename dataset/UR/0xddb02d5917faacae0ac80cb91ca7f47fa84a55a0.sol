 

pragma solidity ^0.4.8;

contract Owned {
  address public owner;

  function Owned() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    owner = newOwner;
  }
}

contract FidgetSpinner is Owned {
  int omega;
  int theta;
  uint public lastUpdate;

  uint public decayRate;
  uint public omegaPerEther;

  int public largestRetro;
  int public largestPro;

  event Spin(
    address indexed from,
    int indexed direction,
    uint amount
  );

   
	function FidgetSpinner(uint _decayRate, uint _omegaPerEther) {
    lastUpdate = now;
		decayRate = _decayRate;
    omegaPerEther = _omegaPerEther;
	}


   
  function deltaTime() constant returns(uint) {
    return now - lastUpdate;
  }

   
  function getCurrentVelocity() constant returns(int) {
    int dir = -1;
    if(omega == 0) {
      return 0;
    } else if(omega < 0) {
      dir = 1;
    }

    uint timeElapsed = deltaTime();
    uint deltaOmega = timeElapsed * decayRate;
    int newOmega = omega + (int(deltaOmega) * dir);

     
    if((omega > 0 && newOmega < 0) || (omega < 0 && newOmega > 0)) {
      return 0;
    }

    return newOmega;
  }

   
  function getCurrentDisplacement() constant returns(int) {
     
    int timeElapsed = int(deltaTime());

     
    int maxTime = omega / int(decayRate);

    if (maxTime < 0) {
      maxTime *= -1;
    }

    if(timeElapsed > maxTime) {
      timeElapsed = maxTime;
    }

    int deltaTheta = ((omega + getCurrentVelocity()) * timeElapsed) / 2;
    return theta + deltaTheta;
  }

   
  function spin(int direction) payable {
    require(direction == -1 || direction == 1);

    int deltaOmega = (int(msg.value) * direction * int(omegaPerEther)) / 1 ether;
    int newOmega = getCurrentVelocity() + deltaOmega;
    int newTheta = getCurrentDisplacement();

    omega = newOmega;
    theta = newTheta;

    if(-omega > largestRetro) {
      largestRetro = -omega;
    } else if(omega > largestPro) {
      largestPro = omega;
    }

    Spin(msg.sender, direction, msg.value);
    lastUpdate = now;
  }

   
  function withdrawAll() onlyOwner {
    withdraw(address(this).balance);
  }

   
  function withdraw(uint amount) onlyOwner {
    owner.transfer(amount);
  }
}