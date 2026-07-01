#pragma once

#include <string>

namespace stts
{
	struct TtsOptions
	{
		std::string mode = "add";
		int preSilenceMs = 0;
		int postSilenceMs = 0;

		TtsOptions(
			const std::string& mode,
			int preSilenceMs,
			int postSilenceMs)
			: mode(mode),
			preSilenceMs(preSilenceMs),
			postSilenceMs(postSilenceMs)
		{
		}
	};
};