/*
 * RenderManager - exporting logic common between the CLI and GUI.
 *
 * Copyright (c) 2015 Ryan Roden-Corrent <ryan/at/rcorre.net>
 *
 * This file is part of LMMS - https://lmms.io
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program (see COPYING); if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 */

#include <QDir>
#include <QRegularExpression>

#include "RenderManager.h"

#include "Engine.h"
#include "Mixer.h"
#include "InstrumentTrack.h"
#include "SampleTrack.h"

#include "PatternStore.h"
#include "Song.h"


namespace lmms
{

RenderManager::RenderManager(
	const OutputSettings& outputSettings, ProjectRenderer::ExportFileFormat fmt, QString outputPath)
	: m_outputSettings(outputSettings)
	, m_format(fmt)
	, m_outputPath(outputPath)
{
	Engine::audioEngine()->storeAudioDevice();
}

RenderManager::~RenderManager()
{
	Engine::audioEngine()->restoreAudioDevice();  // Also deletes audio dev.
}

void RenderManager::abortProcessing()
{
	if ( m_activeRenderer ) {
		disconnect( m_activeRenderer.get(), SIGNAL(finished()),
				this, SLOT(renderNextTrack()));
		m_activeRenderer->abortProcessing();
	}
	restoreMutedState();
}

// Called to render each new track when rendering tracks individually.
void RenderManager::renderNextTrack()
{
	m_activeRenderer.reset();

	if (m_tracksToRender.empty())
	{
		// nothing left to render
		restoreMutedState();
		emit finished();
	}
	else
	{
		// pop the next track from our rendering queue
		Track* renderTrack = m_tracksToRender.back();
		m_tracksToRender.pop_back();

		// Clear any previous force-mute state from all channels
		const mix_ch_t numChannels = Engine::mixer()->numChannels();
		for (mix_ch_t ch = 0; ch < numChannels; ++ch)
		{
			MixerChannel* channel = Engine::mixer()->mixerChannel(ch);
			if (channel) {
				channel->setForceMute(false);
			}
		}

		// Determine the mixer channel index of the active render track
		int renderingChannelIndex = -1;
		if (renderTrack->type() == Track::Type::Instrument)
		{
			InstrumentTrack* instTrack = static_cast<InstrumentTrack*>(renderTrack);
			if (instTrack->mixerChannelModel()) {
				renderingChannelIndex = instTrack->mixerChannelModel()->value();
			}
		}
		else if (renderTrack->type() == Track::Type::Sample)
		{
			SampleTrack* sampleTrack = static_cast<SampleTrack*>(renderTrack);
			if (sampleTrack->mixerChannelModel()) {
				renderingChannelIndex = sampleTrack->mixerChannelModel()->value();
			}
		}

		// Force-mute all non-rendering tracks, except Master (index 0) and the rendering track's own channel
		for (auto track : m_unmuted)
		{
			if (track == renderTrack) { continue; }

			int channelIndex = -1;
			if (track->type() == Track::Type::Instrument)
			{
				InstrumentTrack* instTrack = static_cast<InstrumentTrack*>(track);
				if (instTrack->mixerChannelModel()) {
					channelIndex = instTrack->mixerChannelModel()->value();
				}
			}
			else if (track->type() == Track::Type::Sample)
			{
				SampleTrack* sampleTrack = static_cast<SampleTrack*>(track);
				if (sampleTrack->mixerChannelModel()) {
					channelIndex = sampleTrack->mixerChannelModel()->value();
				}
			}

			if (channelIndex > 0 && channelIndex != renderingChannelIndex && channelIndex < numChannels)
			{
				MixerChannel* channel = Engine::mixer()->mixerChannel(channelIndex);
				if (channel) {
					channel->setForceMute(true);
				}
			}
		}

		// for multi-render, prefix each output file with a different number
		int trackNum = m_tracksToRender.size() + 1;

		render( pathForTrack(renderTrack, trackNum) );
	}
}

// Render the song into individual tracks
void RenderManager::renderTracks()
{
	const TrackContainer::TrackList& tl = Engine::getSong()->tracks();

	// find all currently unnmuted tracks -- we want to render these.
	for (const auto& tk : tl)
	{
		Track::Type type = tk->type();

		// Don't render automation tracks
		if ( tk->isMuted() == false &&
				( type == Track::Type::Instrument || type == Track::Type::Sample ) )
		{
			m_unmuted.push_back(tk);
		}
	}

	const TrackContainer::TrackList& t2 = Engine::patternStore()->tracks();
	for (const auto& tk : t2)
	{
		Track::Type type = tk->type();

		// Don't render automation tracks
		if ( tk->isMuted() == false &&
				( type == Track::Type::Instrument || type == Track::Type::Sample ) )
		{
			m_unmuted.push_back(tk);
		}
	}

	// copy the list of unmuted tracks into our rendering queue.
	// we need to remember which tracks were unmuted to restore state at the end.
	m_tracksToRender = m_unmuted;

	renderNextTrack();
}

// Render the song into a single track
void RenderManager::renderProject()
{
	render( m_outputPath );
}

void RenderManager::render(QString outputPath)
{
	m_activeRenderer = std::make_unique<ProjectRenderer>(m_outputSettings, m_format, outputPath);

	if( m_activeRenderer->isReady() )
	{
		// pass progress signals through
		connect( m_activeRenderer.get(), SIGNAL(progressChanged(int)),
				this, SIGNAL(progressChanged(int)));

		// when it is finished, render the next track.
		// if we have not queued any tracks, renderNextTrack will just clean up
		connect( m_activeRenderer.get(), SIGNAL(finished()),
				this, SLOT(renderNextTrack()));

		m_activeRenderer->startProcessing();
	}
	else
	{
		qDebug( "Renderer failed to acquire a file device!" );
		renderNextTrack();
	}
}

// Clear the force-mute flag on all channels that were affected during export
void RenderManager::restoreMutedState()
{
	for (mix_ch_t ch = 0; ch < Engine::mixer()->numChannels(); ++ch)
	{
		Engine::mixer()->mixerChannel(ch)->setForceMute(false);
	}

	while (!m_unmuted.empty())
	{
		m_unmuted.pop_back();
	}
}

// Determine the output path for a track when rendering tracks individually
QString RenderManager::pathForTrack(const Track *track, int num)
{
	QString extension = ProjectRenderer::getFileExtensionFromFormat( m_format );
	QString name = track->name();
	name = name.remove(QRegularExpression(FILENAME_FILTER));
	name = QString( "%1_%2%3" ).arg( num ).arg( name ).arg( extension );
	return QDir(m_outputPath).filePath(name);
}

void RenderManager::updateConsoleProgress()
{
	if ( m_activeRenderer )
	{
		m_activeRenderer->updateConsoleProgress();

		int totalNum = m_unmuted.size();
		if ( totalNum > 0 )
		{
			// we are rendering multiple tracks, append a track counter to the output
			int trackNum = totalNum - m_tracksToRender.size();
			fprintf( stderr, "(%d/%d)", trackNum, totalNum );
		}
	}
}


} // namespace lmms