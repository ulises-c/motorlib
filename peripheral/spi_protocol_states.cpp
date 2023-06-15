#include "spi_protocol.h"

const SpiProtocol::StateTableEntry SpiProtocol::state_table_[kStateCount] =
{
  [kStateInit           ] = {NULL                                     },
  [kStateWaitForSync    ] = {&SpiProtocol::stateWaitForSyncHandler    },
  [kStateWaitForAck     ] = {&SpiProtocol::stateWaitForAckHandler     },
  [kStateSendAckNack    ] = {&SpiProtocol::stateSendAckNackHandler    },
  [kStateWaitForCommand ] = {&SpiProtocol::stateWaitForCommandHandler },
  [kStateRunCommand     ] = {&SpiProtocol::stateRunCommandHandler     },
};

SpiProtocol::State SpiProtocol::sendAckNack(bool send_nack, State state_after_ack)
{
  send_nack_ = send_nack;
  state_after_ack_ = state_after_ack;
  return kStateSendAckNack;
}

SpiProtocol::State SpiProtocol::stateWaitForSyncHandler(bool first_run)
{
  State new_state = kStateWaitForSync;

  // Reset SPI
  spi_slave_.reset();

  if(  (!first_run)
     &&(rx_protocol_buffer_[0] == (uint8_t)Command::kSync)
     &&(rx_protocol_buffer_[1] == 0x00) )
  {
    new_state = sendAckNack(false, kStateWaitForCommand);
  }
  else
  {
    // Read 2 bytes from SPI looking for Sync sequence
    spi_slave_.startTransaction({
      .txBuffer = NULL,
      .rxBuffer = rx_protocol_buffer_,
      .length = 2
    });
  }

  return new_state;
}

SpiProtocol::State SpiProtocol::stateSendAckNackHandler(bool first_run)
{
  static uint8_t response_ack[2] = {0x00, (uint8_t)Command::kAck};
  static uint8_t response_nack[2] = {0x00, (uint8_t)Command::kNack};

  State new_state = kStateSendAckNack;

  if(first_run)
  {
    // Send the dummy byte (0x00) and Ack/Nack
    spi_slave_.startTransaction({
      .txBuffer = (send_nack_) ? response_nack : response_ack,
      .rxBuffer = NULL,
      .length = 2
    });
  }
  else
  {
    new_state = kStateWaitForAck;
  }

  return new_state;
}

SpiProtocol::State SpiProtocol::stateWaitForAckHandler(bool first_run)
{
  State new_state = kStateWaitForAck;

  if(first_run)
  {
    wait_for_ack_cycles_ = 0;
  }

  if(  (!first_run)
     &&(rx_protocol_buffer_[0] == (uint8_t)Command::kAck) )
  {
    new_state = state_after_ack_;
  }
  else
  {
    if(wait_for_ack_cycles_++ < 100U)
    {
      spi_slave_.startTransaction({
        .txBuffer = NULL,
        .rxBuffer = rx_protocol_buffer_,
        .length = 1
      });
    }
    else // Loss of synchronization
    {
      new_state = kStateWaitForSync;
    }
  }

  return new_state;
}

SpiProtocol::State SpiProtocol::stateWaitForCommandHandler(bool first_run)
{
  State new_state = kStateWaitForCommand;
  size_t i;

  if(first_run)
  {
    spi_slave_.startTransaction({
      .txBuffer = NULL,
      .rxBuffer = rx_protocol_buffer_,
      .length = 3
    });
  }
  else
  {
    if(  (rx_protocol_buffer_[0] == (uint8_t)Command::kSync)
       &&((rx_protocol_buffer_[1] ^ rx_protocol_buffer_[2]) == 0xFF) )
    {
      current_command_ = (Command)rx_protocol_buffer_[1];

      // Check if the command is in the command_table
      for(i = 0; i < FIGURE_COUNTOF(command_table_); i++)
      {
        if(command_table_[i].command == current_command_)
        {
          // Call the init method of the command
          if(command_table_[i].init != NULL)
          {
            (this->*command_table_[i].init)();
          }

          // Send ACK, transition into kRunCommand state
          new_state = sendAckNack(false, kStateRunCommand);
          break;
        }
      }

      // If command has not been found - send Nack, go back to kWaitForCommand
      if(i >= FIGURE_COUNTOF(command_table_))
      {
        new_state = sendAckNack(true, kStateWaitForCommand);
      }
    }
    else
    {
      new_state = sendAckNack(true, kStateWaitForCommand);
    }
  }

  return new_state;
}

SpiProtocol::State SpiProtocol::stateRunCommandHandler(bool first_run)
{
  State new_state = kStateRunCommand;
  size_t i;

  // Iterate through the command table, look for a command
  for(i = 0; i < FIGURE_COUNTOF(command_table_); i++)
  {
    if(command_table_[i].command == current_command_)
    {
      if(command_table_[i].stateHandler != NULL)
      {
        // Call the command state handler
        new_state = (this->*command_table_[i].stateHandler)(first_run);
        break;
      }
    }
  }

  // Command should be guaranteed to be in the table at this point
  FIGURE_ASSERT(i < FIGURE_COUNTOF(command_table_), "Logic error");

  return new_state;
}
