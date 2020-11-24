 

contract echo {
   
  function () {
    msg.sender.send(msg.value);
  }
}