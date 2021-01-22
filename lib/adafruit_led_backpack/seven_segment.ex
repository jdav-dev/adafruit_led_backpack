defmodule AdafruitLedBackpack.SevenSegment do
  @moduledoc "Seven segment LED backpack display."

  use AdafruitLedBackpack.Ht16k33

  import Bitwise

  alias AdafruitLedBackpack.Ht16k33

  def set_digit_raw(server \\ __MODULE__, pos, bitmask, opts \\ []) when pos in 0..3 do
    invert = Keyword.get(opts, :invert, false)

    final_pos =
      pos
      |> skip_colon()
      |> maybe_invert_pos(invert)

    Ht16k33.update_buffer(server, final_pos * 2, fn _value -> bitmask &&& 0xFF end)
  end

  defp skip_colon(pos) when pos < 2, do: pos
  defp skip_colon(pos), do: pos + 1

  defp maybe_invert_pos(pos, true), do: 4 - pos
  defp maybe_invert_pos(pos, false), do: pos

  def set_decimal(server \\ __MODULE__, pos, decimal, opts \\ [])
      when pos in 0..3 and decimal in [:on, :off] do
    invert = Keyword.get(opts, :invert, false)

    final_pos =
      pos
      |> skip_colon()
      |> maybe_invert_pos(invert)

    update_fun =
      case decimal do
        :on -> &(&1 ||| 1 <<< 7)
        :off -> &(&1 &&& ~~~(1 <<< 7))
      end

    Ht16k33.update_buffer(server, final_pos * 2, update_fun)
  end

  def set_digit(server \\ __MODULE__, pos, digit, opts \\ []) when pos in 0..3 do
    invert = Keyword.get(opts, :invert, false)
    decimal = opts[:decimal] || :off

    value =
      case invert do
        true -> inverted_digit_value(digit)
        false -> digit_value(digit)
      end

    with :ok <- set_digit_raw(server, pos, value, opts) do
      case decimal do
        :on -> set_decimal(pos, :on)
        _off -> :ok
      end
    end
  end

  defp digit_value(digit)
  defp digit_value(space) when space in [" ", ' ', ?\s], do: 0x00
  defp digit_value(hyphen) when hyphen in ["-", '-', ?-], do: 0x40
  defp digit_value(zero) when zero in [0, 0.0, "0", '0', ?0], do: 0x3F
  defp digit_value(one) when one in [1, 1.0, "1", '1', ?\1], do: 0x06
  defp digit_value(two) when two in [2, 2.0, "2", '2', ?2], do: 0x5B
  defp digit_value(three) when three in [3, 3.0, "3", '3', ?3], do: 0x4F
  defp digit_value(four) when four in [4, 4.0, "4", '4', ?4], do: 0x66
  defp digit_value(five) when five in [5, 5.0, "5", '5', ?5], do: 0x6D
  defp digit_value(six) when six in [6, 6.0, "6", '6', ?6], do: 0x7D
  defp digit_value(seven) when seven in [7, 7.0, "7", '7', ?7], do: 0x07
  defp digit_value(eight) when eight in [8, 8.0, "8", '8', ?8], do: 0x7F
  defp digit_value(nine) when nine in [9, 9.0, "9", '9', ?9], do: 0x6F
  defp digit_value(a) when a in ["A", "a", 'A', 'a', ?A, ?a], do: 0x77
  defp digit_value(b) when b in ["B", "b", 'B', 'b', ?B, ?b], do: 0x7C
  defp digit_value(c) when c in ["C", "c", 'C', 'c', ?C, ?c], do: 0x39
  defp digit_value(d) when d in ["D", "d", 'D', 'd', ?D, ?d], do: 0x5E
  defp digit_value(e) when e in ["E", "e", 'E', 'e', ?E, ?e], do: 0x79
  defp digit_value(f) when f in ["F", "f", 'F', 'f', ?F, ?f], do: 0x71
  defp digit_value(_), do: 0x00

  defp inverted_digit_value(digit)
  defp inverted_digit_value(space) when space in [" ", ' ', ?\s], do: 0x00
  defp inverted_digit_value(hyphen) when hyphen in ["-", '-', ?-], do: 0x40
  defp inverted_digit_value(zero) when zero in [0, 0.0, "0", '0', ?0], do: 0x3F
  defp inverted_digit_value(one) when one in [1, 1.0, "1", '1', ?\1], do: 0x30
  defp inverted_digit_value(two) when two in [2, 2.0, "2", '2', ?2], do: 0x5B
  defp inverted_digit_value(three) when three in [3, 3.0, "3", '3', ?3], do: 0x79
  defp inverted_digit_value(four) when four in [4, 4.0, "4", '4', ?4], do: 0x74
  defp inverted_digit_value(five) when five in [5, 5.0, "5", '5', ?5], do: 0x6D
  defp inverted_digit_value(six) when six in [6, 6.0, "6", '6', ?6], do: 0x6F
  defp inverted_digit_value(seven) when seven in [7, 7.0, "7", '7', ?7], do: 0x38
  defp inverted_digit_value(eight) when eight in [8, 8.0, "8", '8', ?8], do: 0x7F
  defp inverted_digit_value(nine) when nine in [9, 9.0, "9", '9', ?9], do: 0x6F
  defp inverted_digit_value(a) when a in ["A", "a", 'A', 'a', ?A, ?a], do: 0x7E
  defp inverted_digit_value(b) when b in ["B", "b", 'B', 'b', ?B, ?b], do: 0x67
  defp inverted_digit_value(c) when c in ["C", "c", 'C', 'c', ?C, ?c], do: 0x0F
  defp inverted_digit_value(d) when d in ["D", "d", 'D', 'd', ?D, ?d], do: 0x73
  defp inverted_digit_value(e) when e in ["E", "e", 'E', 'e', ?E, ?e], do: 0x4F
  defp inverted_digit_value(f) when f in ["F", "f", 'F', 'f', ?F, ?f], do: 0x4E
  defp inverted_digit_value(_), do: 0x00

  def set_colon(server \\ __MODULE__, colon) when colon in [:on, :off] do
    case colon do
      :on -> Ht16k33.update_buffer(server, 4, &(&1 ||| 0x02))
      :off -> Ht16k33.update_buffer(server, 4, &(&1 &&& ~~~0x02 &&& 0xFF))
    end
  end

  def set_left_colon(server \\ __MODULE__, colon) when colon in [:on, :off] do
    case colon do
      :on ->
        Ht16k33.update_buffer(server, 4, &(&1 ||| 0x04))
        Ht16k33.update_buffer(server, 4, &(&1 ||| 0x08))

      :off ->
        Ht16k33.update_buffer(server, 4, &(&1 &&& ~~~0x04 &&& 0xFF))
        Ht16k33.update_buffer(server, 4, &(&1 &&& ~~~0x08 &&& 0xFF))
    end
  end

  def set_fixed_decimal(server \\ __MODULE__, decimal) when decimal in [:on, :off] do
    case decimal do
      :on -> Ht16k33.update_buffer(server, 4, &(&1 ||| 0x10))
      :off -> Ht16k33.update_buffer(server, 4, &(&1 &&& ~~~0x10 &&& 0xFF))
    end
  end

  def print_number_str(server \\ __MODULE__, value, opts \\ []) do
    justify_right = Keyword.get(opts, :justify_right, true)
    opts_without_decimal = Keyword.delete(opts, :decimal)

    graphemes = String.graphemes(value)
    length_without_decimals = graphemes |> Enum.reject(&(&1 == ".")) |> length()

    pos =
      case justify_right do
        true -> 4 - length_without_decimals
        false -> 0
      end

    if length_without_decimals > 4 do
      print_number_str(server, "----", opts_without_decimal)
    else
      graphemes
      |> Enum.with_index()
      |> Enum.each(fn
        {".", index} -> set_decimal(server, pos + index - 1, :on, opts_without_decimal)
        {grapheme, index} -> set_digit(server, pos + index, grapheme, opts_without_decimal)
      end)
    end
  end

  def print_float(server \\ __MODULE__, value, opts \\ []) do
    {decimal_digits, opts_without_decimal_digits} = Keyword.pop(opts, :decimal_digits, 2)
    formatted_value = value |> Float.round(decimal_digits) |> to_string()
    print_number_str(server, formatted_value, opts_without_decimal_digits)
  end

  def print_hex(server \\ __MODULE__, value, opts \\ []) when value in 0..0xFFFF do
    formatted_value = Integer.to_string(value, 16)
    print_number_str(server, formatted_value, opts)
  end
end
